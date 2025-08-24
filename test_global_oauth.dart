import 'package:flutter/material.dart';
import 'package:red_helper/utils/global_oauth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🧪 开始测试全局OAuth管理器...");

  final oAuthManager = GlobalOAuthManager();

  try {
    // 初始化
    print("📋 初始化全局OAuth管理器...");
    await oAuthManager.initialize();

    // 获取token状态
    final status = oAuthManager.getTokenStatus();
    print("📊 Token状态: $status");

    // 尝试获取访问令牌
    print("🔑 尝试获取访问令牌...");
    final token = await oAuthManager.getAccessToken();
    print("✅ 成功获取访问令牌，长度: ${token.length} 字符");
    print(
      "🔑 Token预览: ${token.substring(0, token.length > 20 ? 20 : token.length)}...",
    );

    // 再次获取token状态
    final newStatus = oAuthManager.getTokenStatus();
    print("📊 更新后的Token状态: $newStatus");

    print("🎉 全局OAuth管理器测试成功！");
  } catch (e) {
    print("❌ 全局OAuth管理器测试失败: $e");
  }
}


