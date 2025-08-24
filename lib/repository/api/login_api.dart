import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ApiService {
  static const String _baseUrl = 'http://192.168.137.1:8080';
  static const String _tokenKey = 'auth_token';
  static const String _expiresInKey = 'token_expires_in';
  static const String _userIdKey = 'user_id';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // 初始化Dio实例，设置拦截器
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      _dio.options.headers['token'] = token;
    }

    // 添加请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 打印请求信息（开发环境）
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 打印响应信息（开发环境）
          print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // 打印错误信息
          print(
            'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
          );
          return handler.next(e);
        },
      ),
    );
  }

  // 注册新用户
  static Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String username,
    required String password,
    //required String nickname,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {'username': username, 'password': password},
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode != 200) {
        throw FormatException(response.data['error'] ?? '注册失败');
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw '注册失败: ${e.toString()}';
    }
  }

  // 用户登录
  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'username': identifier, 'password': password},
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode != 200) {
        final errors = response.data['errors'];
        if (errors != null && errors is Map) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw FormatException(firstError.first.toString());
          }
        }
        throw FormatException('登录失败: ${response.data['message'] ?? '未知错误'}');
      }
      // 保存令牌和用户信息
      await _saveAuthData(token: response.data['data']['token']);

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw '登录失败: ${e.toString()}';
    }
  }

  // 保存认证数据到本地存储
  static Future<void> _saveAuthData({required String token}) async {
    final prefs = await SharedPreferences.getInstance();

    // 计算过期时间戳

    await Future.wait([
      prefs.setString(_tokenKey, token),
      prefs.setString('token', token),
    ]);

    // 更新Dio实例的认证头
    _dio.options.headers['token'] = token;
  }

  // 用户登出
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userIdKey),
      prefs.remove(_expiresInKey),
    ]);

    // 清除Dio实例的认证头
    _dio.options.headers.remove('token');
  }

  // 处理Dio错误
  static String _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送请求超时';
      case DioExceptionType.receiveTimeout:
        return '接收响应超时';
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          // 认证失败，清除本地令牌
          logout();
          return '认证失败，请重新登录';
        }
        if (statusCode == 403) return '权限不足';
        return '服务器异常（${statusCode ?? '未知'}）';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return '网络连接异常';
    }
  }

  // 获取当前登录用户ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // 检查用户是否已登录
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiresAt = prefs.getInt(_expiresInKey);

    if (token == null || expiresAt == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    return now < expiresAt;
  }
}
