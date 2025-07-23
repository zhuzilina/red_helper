import 'dart:async';

import 'package:dio/dio.dart';
import 'package:red_helper/repository/models/model.dart';
import 'package:red_helper/api_exception/api_exception.dart';

class ApiService {
  String token;
  final Dio _dio;

  ApiService(this.token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'http://81.71.152.77:8080',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token.isNotEmpty) {
            options.headers['token'] = token;
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<Friend>> getFriendRanking() async {
    try {
      final response = await _dio.get('/statistics/pointsranking');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((item) => Friend.fromJson(item))
            .toList();
      } else {
        // 明确处理非 200 状态码
        throw ApiException(
          statusCode: 200,
          message: '获取好友排行失败',
          data: response.data,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException(
          statusCode: 401,
          message: '登录已过期',
          data: e.response?.data,
        );
      }
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message ?? '未知错误',
        data: e.response?.data,
      );
    }
  }

  Future<List<PointsCategory>> getPointsDistribution() async {
    try {
      final response = await _dio.get('/points/distribution');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .asMap() // 转换为 Map<index, value>
            .entries // 获取键值对集合
            .map((entry) {
              final index = entry.key;
              final item = entry.value;
              return PointsCategory.fromJson(item, index); // 传递索引
            })
            .toList();
      }
      throw ApiException(
        statusCode: 500,
        message: "Failed to load PointsDistribution",
        data: null,
      );
    } on DioException catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "请求失败：${e.message}",
        data: null,
      );
    }
  }

  Future<List<Book>> getBookWinnow() async {
    try {
      final response = await _dio.get('/carouse/get');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((item) => Book.fromJson(item))
            .toList();
      }
      throw ApiException(
        statusCode: 500,
        message: "Failed to load BookWinnow",
        data: null,
      );
    } on DioException catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "请求失败：${e.message}",
        data: null,
      );
    }
  }

  Future<List<Book>> getBook() async {
    try {
      final response = await _dio.get('/carouse/list');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((item) => Book.fromJson(item))
            .toList();
      }
      throw ApiException(
        statusCode: 500,
        message: "Failed to load BookWinnow",
        data: null,
      );
    } on DioException catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "请求失败：${e.message}",
        data: null,
      );
    }
  }

  Future<int> getUserPoints() async {
    try {
      final response = await _dio.get('/points/total');
      if (response.statusCode == 200) {
        return response.data['data'] as int;
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: '获取积分失败',
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "请求失败：${e.message}",
        data: null,
      );
    }
  }

  Future<List<DailyTask>> getDailyTask() async {
    try {
      final response = await _dio.get('/points/DailyTask');
      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((item) => DailyTask.fromJson(item))
            .toList();
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: '获取任务失败',
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "请求失败：${e.message}",
        data: null,
      );
    }
  }

  Future<int> exchangeProduct(int productId) async {
    try {
      final response = await _dio.post(
        '/exchange',
        data: {'productId': productId},
      );
      if (response.statusCode == 200) {
        return response.data['data']['newPoints'] as int;
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: '兑换商品失败',
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "请求失败：${e.message}",
        data: null,
      );
    }
  }

  Future<bool> updateTask() async {
    try {
      final response = await _dio.get('/points/signin');
      if (response.statusCode == 200) {
        return true;
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: '获取任务失败',
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "请求失败：${e.message}",
        data: null,
      );
    }
  }
}
