import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkUtils {
  /// 检查网络连接状态
  static Future<bool> hasNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // 如果无法检查网络状态，假设有网络连接
      return true;
    }
  }

  /// 安全地更新网络状态（检查mounted状态）
  static Future<bool> updateNetworkState(
    State state, {
    required Function(bool) onNetworkChanged,
    required Function(String) onErrorChanged,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      if (!state.mounted) return hasConnection; // 提前检查mounted状态

      state.setState(() {
        onNetworkChanged(hasConnection);
        if (!hasConnection) {
          onErrorChanged('网络连接不可用，请检查网络设置');
        } else {
          onErrorChanged('');
        }
      });

      return hasConnection;
    } catch (e) {
      // 如果无法检查网络状态，假设有网络连接
      if (state.mounted) {
        state.setState(() {
          onNetworkChanged(true);
          onErrorChanged('');
        });
      }
      return true;
    }
  }

  /// 获取网络错误信息
  static String getNetworkErrorMessage(String? customMessage) {
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }
    return '网络连接不可用，请检查网络设置';
  }

  /// 检查是否为网络相关错误
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable') ||
        errorString.contains('no internet') ||
        errorString.contains('dioexception');
  }

  /// 安全地调用setState（检查mounted状态）
  static void safeSetState(State state, VoidCallback fn) {
    if (state.mounted) {
      state.setState(fn);
    }
  }
}
