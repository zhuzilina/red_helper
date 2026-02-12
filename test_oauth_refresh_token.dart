import 'package:flutter/material.dart';
import 'package:red_helper/utils/global_oauth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🧪 开始测试OAuth刷新token功能...");

  final oAuthManager = GlobalOAuthManager();

  try {
    // 初始化
    print("📋 初始化全局OAuth管理器...");
    await oAuthManager.initialize();

    // 获取初始状态
    final initialStatus = oAuthManager.getTokenStatus();
    print("📊 初始Token状态:");
    _printTokenStatus(initialStatus);

    // 尝试获取访问令牌
    print("\n🔑 尝试获取访问令牌...");
    final token = await oAuthManager.getAccessToken();
    print("✅ 成功获取访问令牌，长度: ${token.length} 字符");
    print(
      "🔑 Token预览: ${token.substring(0, token.length > 20 ? 20 : token.length)}...",
    );

    // 获取更新后的状态
    final updatedStatus = oAuthManager.getTokenStatus();
    print("\n📊 更新后的Token状态:");
    _printTokenStatus(updatedStatus);

    // 测试手动刷新token
    print("\n🔄 测试手动刷新token...");
    try {
      final refreshedToken = await oAuthManager.refreshToken();
      print("✅ 手动刷新成功，新Token长度: ${refreshedToken.length} 字符");
      print(
        "🔑 新Token预览: ${refreshedToken.substring(0, refreshedToken.length > 20 ? 20 : refreshedToken.length)}...",
      );

      // 获取刷新后的状态
      final refreshedStatus = oAuthManager.getTokenStatus();
      print("\n📊 刷新后的Token状态:");
      _printTokenStatus(refreshedStatus);
    } catch (e) {
      print("❌ 手动刷新失败: $e");
    }

    // 测试token状态监控
    print("\n📊 测试token状态监控...");
    final finalStatus = oAuthManager.getTokenStatus();
    print("📊 最终Token状态:");
    _printTokenStatus(finalStatus);

    print("\n🎉 OAuth刷新token功能测试完成！");
  } catch (e) {
    print("❌ 测试失败: $e");
  }
}

void _printTokenStatus(Map<String, dynamic> status) {
  print("  - 有访问令牌: ${status['hasAccessToken']}");
  print("  - 有刷新令牌: ${status['hasRefreshToken']}");
  print("  - 令牌有效: ${status['isValid']}");
  print("  - 过期时间: ${status['expiry']}");
  print("  - 剩余秒数: ${status['timeUntilExpiry']}");
  print("  - 正在刷新: ${status['isRefreshing']}");
  print("  - 等待请求数: ${status['pendingRequests']}");
  print("  - 访问令牌长度: ${status['accessTokenLength']}");
  print("  - 刷新令牌长度: ${status['refreshTokenLength']}");
}


