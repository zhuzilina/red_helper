import 'package:flutter/foundation.dart';

import '../api_exception/api_exception.dart';
import '../repository/api/api.dart';

class PointsState with ChangeNotifier {
  final ApiService _apiService;
  int currentPoints = 256;
  bool _isLoading = false;
  String? _error;

  PointsState(this._apiService) {
    if (_apiService.token.isNotEmpty) {
      fetchPoints();
    }
  }

  Future<void> fetchPoints() async {
    if (_apiService.token.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      currentPoints = await _apiService.getUserPoints();
      _error = null;
    } on ApiException catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleError(ApiException e) {
    if (e.statusCode == 401) {
      currentPoints = -1;
      _error = '登录已过期';
    } else {
      _error = e.message ?? '获取积分失败';
    }
  }

  Future<void> exchangeProduct(int productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPoints = await _apiService.exchangeProduct(productId);
      currentPoints = newPoints;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}