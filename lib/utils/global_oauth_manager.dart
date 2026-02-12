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

const String redirectUri = "http://localhost:3000/callback";
const String authorizationEndpoint =
    "https://www.coze.cn/api/permission/oauth2/authorize";
const String tokenEndpoint = "https://api.coze.cn/api/permission/oauth2/token";

/// 全局OAuth Token管理器
/// 单例模式，确保整个应用使用同一个token实例
class GlobalOAuthManager {
  static final GlobalOAuthManager _instance = GlobalOAuthManager._internal();
  factory GlobalOAuthManager() => _instance;
  GlobalOAuthManager._internal();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  String? _codeVerifier;
  final Completer<bool> _initCompleter = Completer<bool>();
  bool _isInitialized = false;
  bool _isRefreshing = false;
  final List<Completer<String>> _pendingRequests = [];

  /// 初始化管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

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
      debugPrint('全局OAuth管理器初始化完成: ${_accessToken != null ? "已加载" : "无缓存"}');
    } catch (e) {
      debugPrint('全局OAuth管理器初始化失败: $e');
      _isInitialized = true;
      _initCompleter.complete(false);
    }
  }

  /// 获取访问令牌（核心方法）
  /// 如果token有效直接返回，如果过期则刷新，如果没有则进行完整授权
  Future<String> getAccessToken() async {
    // 等待初始化完成
    if (!_isInitialized) {
      await _initCompleter.future;
    }

    // 如果正在刷新token，等待刷新完成
    if (_isRefreshing) {
      final completer = Completer<String>();
      _pendingRequests.add(completer);
      return completer.future;
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
        _isRefreshing = true;
        final newToken = await _refreshAccessToken();
        _isRefreshing = false;

        // 处理等待中的请求
        for (final completer in _pendingRequests) {
          completer.complete(newToken);
        }
        _pendingRequests.clear();

        return newToken;
      } catch (e) {
        debugPrint('令牌刷新失败: $e，将重新授权');
        _isRefreshing = false;
        await _clearTokenStorage();

        // 处理等待中的请求
        for (final completer in _pendingRequests) {
          completer.completeError(e);
        }
        _pendingRequests.clear();
      }
    }

    // 3. 完整授权流程
    debugPrint('开始完整授权流程...');
    _isRefreshing = true;
    try {
      final newToken = await _completeAuthorizationFlow();
      _isRefreshing = false;

      // 处理等待中的请求
      for (final completer in _pendingRequests) {
        completer.complete(newToken);
      }
      _pendingRequests.clear();

      return newToken;
    } catch (e) {
      _isRefreshing = false;

      // 处理等待中的请求
      for (final completer in _pendingRequests) {
        completer.completeError(e);
      }
      _pendingRequests.clear();

      rethrow;
    }
  }

  /// 检查令牌是否有效
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

  /// 保存令牌到本地存储
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

  /// 清除本地存储的令牌
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

  /// 完整的授权流程
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
      await launchUrl(authorizationUrl, mode: LaunchMode.inAppBrowserView);
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
    await _saveTokenToStorage();

    return _accessToken!;
  }

  /// 启动本地回调服务器
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

  /// 用授权码交换令牌
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

  /// 刷新令牌
  /// 根据OAuth文档实现标准的刷新token API
  Future<String> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('没有可用的refresh_token');
    }

    debugPrint('开始刷新OAuth Access Token...');

    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': clientId,
        }),
      );

      debugPrint('刷新token响应状态码: ${response.statusCode}');
      debugPrint('刷新token响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final tokenResponse = json.decode(response.body);

        // 更新token信息
        _accessToken = tokenResponse['access_token'];
        _refreshToken = tokenResponse['refresh_token']; // 新的refresh_token
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: tokenResponse['expires_in'] as int),
        );

        // 保存到本地存储
        await _saveTokenToStorage();

        debugPrint('✅ OAuth Access Token刷新成功');
        debugPrint('   新token有效期至: $_tokenExpiry');
        debugPrint('   新refresh_token已保存');

        return _accessToken!;
      } else {
        final errorResponse = json.decode(response.body);
        final error = errorResponse['error'] ?? 'unknown_error';
        final errorDescription = errorResponse['error_description'] ?? '未知错误';

        debugPrint('❌ 刷新token失败: $error - $errorDescription');

        // 如果是refresh_token过期或无效，清除本地存储
        if (error == 'invalid_grant' || error == 'invalid_token') {
          debugPrint('🔄 refresh_token已失效，清除本地存储');
          await _clearTokenStorage();
        }

        throw Exception('刷新OAuth Access Token失败 [$error]: $errorDescription');
      }
    } catch (e) {
      debugPrint('❌ 刷新token请求异常: $e');
      throw Exception('刷新OAuth Access Token请求失败: $e');
    }
  }

  /// 生成 Code Verifier
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// 生成 Code Challenge
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// 强制刷新token（公共方法）
  /// 外部可以直接调用此方法来刷新token
  Future<String> refreshToken() async {
    // 等待初始化完成
    if (!_isInitialized) {
      await _initCompleter.future;
    }

    if (_refreshToken == null) {
      throw Exception('没有可用的refresh_token，需要重新授权');
    }

    debugPrint('🔄 手动刷新OAuth Access Token...');
    return await _refreshAccessToken();
  }

  /// 强制清除token缓存（用于调试或重置）
  Future<void> clearTokenCache() async {
    await _clearTokenStorage();
    debugPrint('Token缓存已强制清除');
  }

  /// 获取当前token状态信息
  Map<String, dynamic> getTokenStatus() {
    final now = DateTime.now();
    final timeUntilExpiry = _tokenExpiry != null
        ? _tokenExpiry!.difference(now).inSeconds
        : null;

    return {
      'hasAccessToken': _accessToken != null,
      'hasRefreshToken': _refreshToken != null,
      'isValid': _isTokenValid(),
      'expiry': _tokenExpiry?.toIso8601String(),
      'timeUntilExpiry': timeUntilExpiry, // 剩余秒数
      'isRefreshing': _isRefreshing,
      'pendingRequests': _pendingRequests.length,
      'accessTokenLength': _accessToken?.length ?? 0,
      'refreshTokenLength': _refreshToken?.length ?? 0,
    };
  }
}
