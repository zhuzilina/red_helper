import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lib/utils/global_oauth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🧪 开始测试OAuth token验证...");

  final oAuthManager = GlobalOAuthManager();

  try {
    // 初始化
    print("📋 初始化全局OAuth管理器...");
    await oAuthManager.initialize();

    // 获取token
    print("🔑 获取OAuth Access Token...");
    final token = await oAuthManager.getAccessToken();
    print("✅ 获取token成功，长度: ${token.length} 字符");
    print(
      "🔑 Token预览: ${token.substring(0, token.length > 20 ? 20 : token.length)}...",
    );

    // 测试不同的API端点
    await testApiEndpoint(
      token,
      "https://api.coze.cn/v1/workflow/run",
      "Workflow API",
    );
    await testApiEndpoint(token, "https://api.coze.cn/v3/chat", "Chat API");
    await testApiEndpoint(
      token,
      "https://api.coze.cn/v1/bot/list",
      "Bot List API",
    );

    // 测试token状态
    final status = oAuthManager.getTokenStatus();
    print("\n📊 Token状态:");
    print("  - 有访问令牌: ${status['hasAccessToken']}");
    print("  - 有刷新令牌: ${status['hasRefreshToken']}");
    print("  - 令牌有效: ${status['isValid']}");
    print("  - 剩余秒数: ${status['timeUntilExpiry']}");
  } catch (e) {
    print("❌ 测试失败: $e");
  }
}

Future<void> testApiEndpoint(String token, String url, String apiName) async {
  print("\n🔍 测试 $apiName: $url");

  try {
    final uri = Uri.parse(url);
    final request = http.Request("POST", uri)
      ..headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "User-Agent": "Flutter/1.0",
        "Accept": "application/json",
      })
      ..body = jsonEncode({"test": "validation"});

    print("📤 发送请求...");
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print("📥 响应状态码: ${response.statusCode}");
    print(
      "📄 响应内容: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...",
    );

    if (response.statusCode == 200) {
      print("✅ $apiName 调用成功！");
    } else if (response.statusCode == 401) {
      print("❌ $apiName 返回401 - Token无效");
    } else if (response.statusCode == 403) {
      print("⚠️ $apiName 返回403 - 权限不足");
    } else {
      print("⚠️ $apiName 返回${response.statusCode} - 其他错误");
    }
  } catch (e) {
    print("❌ $apiName 请求异常: $e");
  }
}


