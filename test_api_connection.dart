import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'lib/env.dart';

void main() async {
  print("🔍 开始测试API连接...");

  // 检查配置
  print("📋 配置检查:");
  print("  API Token: ${apiToken.isNotEmpty ? '已设置' : '未设置'}");
  print("  Workflow ID: ${workflowId.isNotEmpty ? '已设置' : '未设置'}");

  if (apiToken.isEmpty || workflowId.isEmpty) {
    print("❌ API配置不完整，请检查env.dart文件");
    return;
  }

  try {
    // 测试API连接
    print("\n🌐 测试API连接...");
    var uri = Uri.parse("https://api.coze.cn/v1/workflow/run");
    var request = http.Request("POST", uri)
      ..headers.addAll({
        "Authorization": "Bearer $apiToken",
        "Content-Type": "application/json",
        "User-Agent": "Flutter/1.0",
        "Accept": "text/event-stream",
      })
      ..body = jsonEncode({
        "workflow_id": workflowId,
        "parameters": {"input": "邓小平"},
      });

    print("📤 发送请求...");
    print("  URL: $uri");
    print("  Headers: ${request.headers}");
    print("  Body: ${request.body}");

    var streamedResponse = await request.send();
    print("\n📥 收到响应:");
    print("  状态码: ${streamedResponse.statusCode}");
    print("  响应头: ${streamedResponse.headers}");

    if (streamedResponse.statusCode != 200) {
      var errorBody = await streamedResponse.stream.bytesToString();
      print("❌ API请求失败:");
      print("  错误响应: $errorBody");
      return;
    }

    print("\n📄 解析响应流...");
    String responseBody = "";
    int lineCount = 0;

    await streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          lineCount++;
          responseBody += line + "\n";

          if (line.startsWith("data:")) {
            print("  行 $lineCount: $line");
            String jsonStr = line.substring(5).trim();
            if (jsonStr.isNotEmpty && jsonStr != "[DONE]") {
              try {
                Map<String, dynamic> event = jsonDecode(jsonStr);
                print("    ✅ JSON解析成功: ${event.keys}");

                if (event.containsKey("content")) {
                  Map<String, dynamic> innerContent = jsonDecode(
                    event["content"],
                  );
                  print("    📝 内部内容: ${innerContent.keys}");

                  if (innerContent.containsKey("output")) {
                    String output = innerContent["output"];
                    print("    🎯 找到输出内容: ${output.length} 字符");
                    print(
                      "    📄 输出预览: ${output.substring(0, output.length > 100 ? 100 : output.length)}...",
                    );
                  }
                }
              } catch (e) {
                print("    ❌ JSON解析失败: $e");
              }
            }
          }
        });

    print("\n📊 响应统计:");
    print("  总行数: $lineCount");
    print("  响应体大小: ${responseBody.length} 字符");

    if (responseBody.contains("output")) {
      print("✅ 响应中包含output字段");
    } else {
      print("❌ 响应中未找到output字段");
    }
  } catch (e) {
    print("❌ 测试过程中发生异常: $e");
  }
}



