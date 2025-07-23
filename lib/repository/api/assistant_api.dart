import 'package:dio/dio.dart';
import 'package:red_helper/repository/models/assistant.dart';
import 'package:red_helper/api_exception/api_exception.dart';

class AssistantService {
  final String token;
  final String ARK_API_KEY = 'db503448-c18e-421a-b9ac-90a4b787e525';
  final Dio _dio;

  AssistantService(this.token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://ark.cn-beijing.volces.com/api/v3/chat/completions',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token.isNotEmpty) {
            options.headers['Content-Type'] = 'application/json';
            options.headers['Authorization'] = 'Bearer $ARK_API_KEY';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Assistant> getAssistantService() async {
    try {
      final response = await _dio.get('/api/test');

      // 明确检查 null 安全
      if (response.statusCode == 200) {
        // 增加 data 空值检查
        if (response.data == null) {
          throw ApiException(statusCode: 200, message: '响应数据为空', data: null);
        }
        return Assistant.fromJson(response.data!);
      } else {
        // 返回错误
        throw ApiException(
          statusCode: response.statusCode ?? 500, // 处理可能的 null
          message: '请求失败，状态码：${response.statusCode}',
          data: response.data,
        );
      }
    } on DioException catch (e) {
      // 处理 Dio 特定错误
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;

      if (statusCode == 401) {
        throw ApiException(
          statusCode: 401,
          message: '登录已过期，请重新登录',
          data: errorData,
        );
      }

      throw ApiException(
        statusCode: statusCode ?? 500, // 网络错误等无状态码情况
        message: e.message ?? '网络请求异常', // Dio 原始错误信息
        data: errorData,
      );
    } catch (e) {
      // 处理其他未知异常（如 JSON 解析错误）
      throw ApiException(
        statusCode: 500,
        message: '系统异常：${e.toString()}',
        data: null,
      );
    }
  }
}
