import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/env.dart';
import 'lib/repository/models/topic.dart';
import 'lib/pages/coze_page/o_auth_service.dart';

void main() async {
  print("🔍 开始测试真实数据获取...");

  try {
    // 检查配置
    print("\n📋 配置检查:");
    print("  Client ID: ${clientId.isNotEmpty ? '已设置' : '未设置'}");
    print("  Workflow ID: ${workflowId.isNotEmpty ? '已设置' : '未设置'}");

    if (clientId.isEmpty || workflowId.isEmpty) {
      print("❌ 配置不完整，请检查env.dart文件");
      return;
    }

    // 测试OAuth认证
    print("\n🔐 测试OAuth认证...");
    final oAuthService = OAuthService();

    try {
      final accessToken = await oAuthService.getAccessToken();
      print("✅ OAuth认证成功");
      print("  Token长度: ${accessToken.length} 字符");

      // 测试API调用
      print("\n🌐 测试API调用...");
      var uri = Uri.parse("https://api.coze.cn/v1/workflow/run");
      var request = http.Request("POST", uri)
        ..headers.addAll({
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
          "User-Agent": "Flutter/1.0",
          "Accept": "text/event-stream",
        })
        ..body = jsonEncode({
          "workflow_id": workflowId,
          "parameters": {"input": "邓小平"},
        });

      print("📤 发送请求...");
      var streamedResponse = await request.send();
      print("📥 收到响应: ${streamedResponse.statusCode}");

      if (streamedResponse.statusCode == 200) {
        print("✅ API调用成功，开始解析数据...");

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
      } else {
        var errorBody = await streamedResponse.stream.bytesToString();
        print("❌ API调用失败: ${streamedResponse.statusCode}");
        print("  错误信息: $errorBody");
      }
    } catch (e) {
      print("❌ OAuth认证失败: $e");
      print("💡 提示：首次使用需要浏览器授权");
    }
  } catch (e) {
    print("❌ 测试过程中发生异常: $e");
  }
}



