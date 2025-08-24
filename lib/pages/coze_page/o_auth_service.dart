import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:red_helper/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:url_launcher/url_launcher.dart';

const String redirectUri = "http://localhost:3000/callback"; // 需与控制台配置一致
const String authorizationEndpoint =
    "https://www.coze.cn/api/permission/oauth2/authorize";
const String tokenEndpoint =
    "https://api.coze.cn/api/permission/oauth2/token"; // 当前官网最新地址

class OAuthService {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  String? _codeVerifier;
  final Completer<bool> _initCompleter = Completer<bool>();
  bool _isInitialized = false;

  OAuthService() {
    _initTokenFromStorage();
  }

  // 从本地存储初始化令牌
  Future<void> _initTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('coze_access_token');
      _refreshToken = prefs.getString('coze_refresh_token');

      final expiryMillis = prefs.getInt('coze_token_expiry');
      if (expiryMillis != null && expiryMillis > 0) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      }
      _isInitialized = true;
      _initCompleter.complete(true);
      debugPrint('令牌初始化完成: ${_accessToken != null ? "已加载" : "无缓存"}');
    } catch (e) {
      debugPrint('令牌初始化失败: $e');
      _isInitialized = true;
      _initCompleter.complete(false);
    }
  }

  // 保存令牌到本地存储
  Future<void> _saveTokenToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('coze_access_token', _accessToken ?? '');
      await prefs.setString('coze_refresh_token', _refreshToken ?? '');
      await prefs.setInt(
        'coze_token_expiry',
        _tokenExpiry?.millisecondsSinceEpoch ?? 0,
      );
      debugPrint('令牌已保存到本地存储');
    } catch (e) {
      debugPrint('保存令牌失败: $e');
    }
  }

  // 清除本地存储的令牌
  Future<void> _clearTokenStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('coze_access_token');
      await prefs.remove('coze_refresh_token');
      await prefs.remove('coze_token_expiry');
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      debugPrint('令牌已从本地存储清除');
    } catch (e) {
      debugPrint('清除令牌失败: $e');
    }
  }

  // 获取访问令牌（核心方法）
  Future<String> getAccessToken() async {
    // 等待初始化完成
    if (!_isInitialized) {
      await _initCompleter.future;
    }

    // 1. 检查令牌是否有效
    if (_isTokenValid()) {
      debugPrint('使用缓存的有效令牌');
      return _accessToken!;
    }

    // 2. 尝试刷新令牌
    if (_refreshToken != null) {
      try {
        debugPrint('尝试刷新令牌...');
        return await _refreshAccessToken();
      } catch (e) {
        debugPrint('令牌刷新失败: $e，将重新授权');
        await _clearTokenStorage(); // 清除无效的刷新令牌
      }
    }

    // 3. 完整授权流程
    debugPrint('开始完整授权流程...');
    return await _completeAuthorizationFlow();
  }

  // 检查令牌是否有效
  bool _isTokenValid() {
    if (_accessToken == null || _tokenExpiry == null) {
      return false;
    }

    // 添加5分钟的缓冲时间，避免在token即将过期时使用
    final bufferTime = Duration(minutes: 5);
    final now = DateTime.now();
    final validUntil = _tokenExpiry!.subtract(bufferTime);

    return now.isBefore(validUntil);
  }

  // 完整的授权流程
  Future<String> _completeAuthorizationFlow() async {
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);

    // 构建授权URL
    final authorizationUrl = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': _generateCodeVerifier().substring(0, 16),
      },
    );
    debugPrint('授权URL: ${authorizationUrl.toString()}');

    // 启动本地回调服务器
    final codeCompleter = Completer<String>();
    final server = await _startCallbackServer(codeCompleter);

    // 打开浏览器让用户授权
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(
        authorizationUrl,
        // 根据平台选择合适的启动模式
        mode: LaunchMode.inAppBrowserView, // 打开系统浏览器（推荐授权场景）
      );
    } else {
      throw Exception('无法打开授权页面: ${authorizationUrl.toString()}');
    }

    // 等待获取授权码
    final code = await codeCompleter.future;
    await server.close();

    // 交换令牌
    final tokenResponse = await _exchangeCodeForToken(code);
    _accessToken = tokenResponse['access_token'];
    _refreshToken = tokenResponse['refresh_token'];
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: tokenResponse['expires_in'] as int),
    );
    await _saveTokenToStorage(); // 保存新令牌

    return _accessToken!;
  }

  // 启动本地回调服务器
  Future<HttpServer> _startCallbackServer(
    Completer<String> codeCompleter,
  ) async {
    shelf.Response handleCallbackRequest(shelf.Request request) {
      final uri = request.requestedUri;
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        codeCompleter.completeError(Exception('授权失败: $error'));
        return shelf.Response.ok('授权失败，请关闭页面返回应用');
      }

      if (code != null) {
        codeCompleter.complete(code);
        return shelf.Response.ok(
          '<html><body>授权成功，请关闭页面返回应用</body></html>',
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      }

      codeCompleter.completeError(Exception('未获取到授权码'));
      return shelf.Response.ok('授权失败，请关闭页面返回应用');
    }

    final server = await io.serve(handleCallbackRequest, 'localhost', 3000);
    debugPrint('回调服务器启动: http://${server.address.host}:${server.port}');
    return server;
  }

  // 用授权码交换令牌
  Future<Map<String, dynamic>> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_verifier': _codeVerifier,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('令牌交换失败 [${response.statusCode}]: ${response.body}');
    }

    return json.decode(response.body);
  }

  // 刷新令牌
  Future<String> _refreshAccessToken() async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
        'client_id': clientId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('刷新令牌失败 [${response.statusCode}]: ${response.body}');
    }

    final tokenResponse = json.decode(response.body);
    _accessToken = tokenResponse['access_token'];
    _refreshToken = tokenResponse['refresh_token'];
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: tokenResponse['expires_in'] as int),
    );
    await _saveTokenToStorage(); // 保存刷新后的令牌

    debugPrint('令牌刷新成功，新有效期至: $_tokenExpiry');
    return _accessToken!;
  }

  // 生成 Code Verifier
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  // 生成 Code Challenge
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
