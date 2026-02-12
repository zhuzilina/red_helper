import 'package:shared_preferences/shared_preferences.dart';
import 'lib/pages/coze_page/o_auth_service.dart';
import 'lib/env.dart';

void main() async {
  print("🔍 开始检查OAuth状态...");

  try {
    // 检查配置
    print("\n📋 配置检查:");
    print("  Client ID: ${clientId.isNotEmpty ? '已设置' : '未设置'}");
    print("  Workflow ID: ${workflowId.isNotEmpty ? '已设置' : '未设置'}");

    if (clientId.isEmpty) {
      print("❌ Client ID未设置");
      return;
    }

    // 检查存储的token
    print("\n🔍 检查存储的Token:");
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('coze_access_token');
    final refreshToken = prefs.getString('coze_refresh_token');
    final expiryMillis = prefs.getInt('coze_token_expiry');

    print(
      "  Access Token: ${accessToken != null ? '已缓存 (${accessToken.length} 字符)' : '未缓存'}",
    );
    print(
      "  Refresh Token: ${refreshToken != null ? '已缓存 (${refreshToken.length} 字符)' : '未缓存'}",
    );

    if (expiryMillis != null && expiryMillis > 0) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      final now = DateTime.now();
      final isExpired = now.isAfter(expiry);
      final timeLeft = expiry.difference(now);

      print("  Token过期时间: $expiry");
      print("  Token状态: ${isExpired ? '已过期' : '有效'}");

      if (!isExpired) {
        print("  剩余时间: ${timeLeft.inMinutes} 分钟");
      }
    } else {
      print("  Token过期时间: 未设置");
    }

    // 测试OAuth服务
    print("\n🔧 测试OAuth服务:");
    final oAuthService = OAuthService();

    print("⏳ 等待初始化...");
    await Future.delayed(const Duration(seconds: 1));

    try {
      print("🔐 尝试获取访问令牌...");
      final newAccessToken = await oAuthService.getAccessToken();

      print("✅ OAuth认证成功！");
      print("🔑 新Token长度: ${newAccessToken.length} 字符");
      print(
        "🔑 新Token预览: ${newAccessToken.substring(0, newAccessToken.length > 30 ? 30 : newAccessToken.length)}...",
      );

      // 检查是否与缓存的token相同
      if (accessToken != null && accessToken == newAccessToken) {
        print("✅ 使用的是缓存的Token");
      } else if (accessToken != null) {
        print("🔄 获取了新的Token（刷新）");
      } else {
        print("🆕 首次获取Token");
      }
    } catch (e) {
      print("❌ OAuth认证失败: $e");
      print("\n💡 可能的原因:");
      print("  1. 网络连接问题");
      print("  2. OAuth配置错误");
      print("  3. Token刷新失败");
      print("  4. 需要重新授权");
    }
  } catch (e) {
    print("❌ 检查过程中发生异常: $e");
  }
}



