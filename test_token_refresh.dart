import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/env.dart';
import 'lib/repository/models/topic.dart';
import 'lib/pages/coze_page/o_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print("🔍 开始测试Token刷新功能...");

  try {
    // 检查配置
    print("\n📋 配置检查:");
    print("  Client ID: ${clientId.isNotEmpty ? '已设置' : '未设置'}");
    print("  Workflow ID: ${workflowId.isNotEmpty ? '已设置' : '未设置'}");

    if (clientId.isEmpty || workflowId.isEmpty) {
      print("❌ 配置不完整，请检查env.dart文件");
      return;
    }

    // 检查当前token状态
    print("\n🔍 检查当前Token状态:");
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('coze_access_token');
    final refreshToken = prefs.getString('coze_refresh_token');
    final expiryMillis = prefs.getInt('coze_token_expiry');

    print("  Access Token: ${accessToken != null ? '已缓存' : '未缓存'}");
    print("  Refresh Token: ${refreshToken != null ? '已缓存' : '未缓存'}");

    if (expiryMillis != null && expiryMillis > 0) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      final now = DateTime.now();
      final isExpired = now.isAfter(expiry);

      print("  Token过期时间: $expiry");
      print("  Token状态: ${isExpired ? '已过期' : '有效'}");
    }

    // 测试API调用
    print("\n🌐 测试API调用...");
    final oAuthService = OAuthService();

    try {
      // 获取token
      final token = await oAuthService.getAccessToken();
      print("✅ 获取Token成功，长度: ${token.length} 字符");

      // 发送API请求
      var uri = Uri.parse("https://api.coze.cn/v1/workflow/run");
      var request = http.Request("POST", uri)
        ..headers.addAll({
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Flutter/1.0",
          "Accept": "text/event-stream",
        })
        ..body = jsonEncode({
          "workflow_id": workflowId,
          "parameters": {"input": "焦裕禄"},
        });

      print("📤 发送API请求...");
      var streamedResponse = await request.send();
      print("📥 收到响应: ${streamedResponse.statusCode}");

      if (streamedResponse.statusCode == 200) {
        print("✅ API调用成功！");

        // 解析响应
        String responseBody = "";
        await streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
              responseBody += line + "\n";
              if (line.startsWith("data:")) {
                print(
                  "  收到数据行: ${line.substring(0, line.length > 50 ? 50 : line.length)}...",
                );
              }
            });

        print("✅ 成功获取真实数据！");
        print("  响应体大小: ${responseBody.length} 字符");
      } else if (streamedResponse.statusCode == 401) {
        var errorBody = await streamedResponse.stream.bytesToString();
        print("❌ API返回401错误: $errorBody");

        // 测试token刷新
        print("\n🔄 测试Token刷新...");
        try {
          // 清除缓存
          await prefs.remove('coze_access_token');
          await prefs.remove('coze_refresh_token');
          await prefs.remove('coze_token_expiry');
          print("✅ 已清除token缓存");

          // 重新获取token
          final newToken = await oAuthService.getAccessToken();
          print("✅ 重新获取Token成功，长度: ${newToken.length} 字符");

          // 重新发送请求
          request = http.Request("POST", uri)
            ..headers.addAll({
              "Authorization": "Bearer $newToken",
              "Content-Type": "application/json",
              "User-Agent": "Flutter/1.0",
              "Accept": "text/event-stream",
            })
            ..body = jsonEncode({
              "workflow_id": workflowId,
              "parameters": {"input": "焦裕禄"},
            });

          print("📤 重新发送API请求...");
          streamedResponse = await request.send();
          print("📥 重新请求响应: ${streamedResponse.statusCode}");

          if (streamedResponse.statusCode == 200) {
            print("✅ 重新认证后API调用成功！");
          } else {
            var newErrorBody = await streamedResponse.stream.bytesToString();
            print(
              "❌ 重新认证后仍然失败: ${streamedResponse.statusCode} - $newErrorBody",
            );
          }
        } catch (e) {
          print("❌ Token刷新失败: $e");
        }
      } else {
        var errorBody = await streamedResponse.stream.bytesToString();
        print("❌ API调用失败: ${streamedResponse.statusCode} - $errorBody");
      }
    } catch (e) {
      print("❌ 测试过程中发生异常: $e");
    }
  } catch (e) {
    print("❌ 测试过程中发生异常: $e");
  }
}



