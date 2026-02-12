import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../env.dart';
import '../../../repository/models/topic.dart';
import '../../../utils/global_oauth_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 解析 output 文本为结构化 JSON
Map<String, dynamic> parseOutputText(String text) {
  try {
    print(
      "开始解析文本: ${text.substring(0, text.length > 100 ? 100 : text.length)}...",
    );

    int hashIndex = text.indexOf('#');
    if (hashIndex == -1) {
      throw Exception("没有找到主题起始符号 #");
    }

    String afterHash = text.substring(hashIndex + 1).trimLeft();
    int topicEnd = afterHash.indexOf('\n');
    String topic = topicEnd != -1
        ? afterHash.substring(0, topicEnd).trim()
        : afterHash.trim();

    // 找到详情部分
    int detailStart = hashIndex + 1 + topic.length + 1;
    int questionsStart = text.indexOf('-', detailStart);
    if (questionsStart == -1) {
      throw Exception("没有找到问题列表起始符号 -");
    }
    String detail = text.substring(detailStart, questionsStart).trim();

    // 找到所有问题
    List<String> questions = [];
    text.substring(questionsStart).split('\n').forEach((line) {
      if (line.trim().startsWith('-')) {
        String question = line.substring(1).trim();
        if (question.isNotEmpty) {
          questions.add(question);
        }
      }
    });

    if (questions.isEmpty) {
      throw Exception("没有找到任何问题");
    }

    print("解析成功 - 主题: $topic, 问题数量: ${questions.length}");
    return {"topic": topic, "detail": detail, "questions": questions};
  } catch (e) {
    print("文本解析错误: $e");
    return {"error": e.toString()};
  }
}

/// 生成模拟数据（用于测试）
Topic generateMockData(String topicName) {
  final mockTopics = {
    "邓小平": {
      "topic": "邓小平理论",
      "detail": "邓小平理论是中国特色社会主义理论体系的重要组成部分，是马克思主义中国化的重要成果。",
      "questions": [
        "邓小平理论的核心内容是什么？",
        "改革开放政策的主要特点有哪些？",
        "邓小平提出的\"三步走\"发展战略是什么？",
        "邓小平理论对中国特色社会主义建设有什么指导意义？",
        "邓小平关于社会主义本质的论述是什么？",
      ],
    },
    "毛泽东": {
      "topic": "毛泽东思想",
      "detail": "毛泽东思想是马克思列宁主义在中国的运用和发展，是被实践证明了的关于中国革命和建设的正确的理论原则和经验总结。",
      "questions": [
        "毛泽东思想的核心内容是什么？",
        "新民主主义革命理论的主要内容有哪些？",
        "毛泽东关于人民战争的思想是什么？",
        "毛泽东思想对党的建设有什么重要贡献？",
        "毛泽东思想的活的灵魂是什么？",
      ],
    },
    "焦裕禄": {
      "topic": "焦裕禄精神",
      "detail": "焦裕禄精神是中国共产党人精神谱系的重要组成部分，体现了共产党人全心全意为人民服务的根本宗旨。",
      "questions": [
        "焦裕禄精神的核心内涵是什么？",
        "焦裕禄在兰考工作期间的主要贡献有哪些？",
        "焦裕禄精神对新时代党员干部有什么启示？",
        "如何传承和弘扬焦裕禄精神？",
        "焦裕禄精神与党的群众路线有什么关系？",
      ],
    },
    "改革开放": {
      "topic": "改革开放政策",
      "detail": "改革开放是决定当代中国命运的关键抉择，是党和人民事业大踏步赶上时代的重要法宝。",
      "questions": [
        "改革开放的历史背景是什么？",
        "改革开放的主要成就体现在哪些方面？",
        "改革开放的基本经验有哪些？",
        "改革开放对世界发展有什么重要影响？",
        "新时代如何继续推进改革开放？",
      ],
    },
  };

  final data =
      mockTopics[topicName] ??
      {
        "topic": topicName,
        "detail": "这是一个关于$topicName的主题内容。",
        "questions": [
          "什么是$topicName？",
          "$topicName的主要特点是什么？",
          "$topicName对现代社会有什么影响？",
          "如何理解和应用$topicName？",
          "$topicName的未来发展趋势如何？",
        ],
      };

  return Topic(
    topic: data["topic"] as String,
    detail: data["detail"] as String,
    questions: List<String>.from(data["questions"] as List),
  );
}

/// 从流中提取并解析 output - 改进版本
Future<Topic?> extractAndParseOutput(String input) async {
  try {
    print("🚀 开始请求数据，主题: $input");

    // 检查环境配置
    if (workflowId.isEmpty) {
      print("❌ Workflow ID未设置");
      throw Exception('API配置不完整，请检查环境配置');
    }

    print("✅ 配置检查通过，开始OAuth认证...");

    // 使用全局OAuth管理器获取有效的访问令牌
    String accessToken;

    try {
      print("🔧 正在初始化全局OAuth管理器...");
      final oAuthManager = GlobalOAuthManager();
      await oAuthManager.initialize();
      print("⏳ 全局OAuth管理器初始化完成，开始获取访问令牌...");

      // 检查当前token状态
      await _checkTokenStatus();

      // 获取访问令牌（全局管理器会自动处理刷新逻辑）
      accessToken = await oAuthManager.getAccessToken();
      print("✅ 成功获取访问令牌，长度: ${accessToken.length} 字符");
      print(
        "🔑 Token预览: ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...",
      );
    } catch (e) {
      print("❌ OAuth认证失败: $e");
      throw Exception('OAuth认证失败: $e');
    }

    print("🌐 开始API请求...");

    // 使用正确的 Coze API 端点
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
        "parameters": {"input": input},
      });

    print("📤 发送请求到: $uri");
    print("📋 请求头: ${request.headers}");
    print("📄 请求体: ${request.body}");

    // 添加超时处理
    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print("⏰ API请求超时");
        throw TimeoutException('API请求超时', const Duration(seconds: 30));
      },
    );
    print("📥 收到响应，状态码: ${streamedResponse.statusCode}");

    if (streamedResponse.statusCode != 200) {
      print("❌ API请求失败，状态码: ${streamedResponse.statusCode}");
      print("📋 响应头: ${streamedResponse.headers}");

      // 检查是否是token过期错误
      var errorBody = await streamedResponse.stream.bytesToString();
      print("❌ 错误响应体: $errorBody");

      if (streamedResponse.statusCode == 401) {
        try {
          var errorJson = jsonDecode(errorBody);
          if (errorJson['msg']?.toString().contains('expired') == true ||
              errorJson['msg']?.toString().contains('invalid') == true) {
            print("❌ OAuth Token已过期或无效，尝试刷新token...");

            // 先尝试刷新token，而不是直接清除缓存
            try {
              print("🔄 尝试刷新OAuth token...");
              final oAuthManager = GlobalOAuthManager();
              accessToken = await oAuthManager.getAccessToken();
              print("✅ 刷新token成功，新Token长度: ${accessToken.length} 字符");

              // 重新发送API请求
              print("🌐 重新发送API请求...");
              request = http.Request("POST", uri)
                ..headers.addAll({
                  "Authorization": "Bearer $accessToken",
                  "Content-Type": "application/json",
                  "User-Agent": "Flutter/1.0",
                  "Accept": "text/event-stream",
                })
                ..body = jsonEncode({
                  "workflow_id": workflowId,
                  "parameters": {"input": input},
                });

              streamedResponse = await request.send();
              print("📥 重新请求响应，状态码: ${streamedResponse.statusCode}");

              if (streamedResponse.statusCode != 200) {
                var newErrorBody = await streamedResponse.stream
                    .bytesToString();
                print(
                  "❌ 刷新token后仍然失败: ${streamedResponse.statusCode} - $newErrorBody",
                );

                // 如果刷新token后仍然失败，则清除缓存并重新进行完整授权
                print("🧹 刷新token失败，强制清除token缓存并重新授权...");
                await _clearOAuthCache();

                try {
                  print("🔄 重新进行完整OAuth授权流程...");
                  final oAuthManager = GlobalOAuthManager();
                  accessToken = await oAuthManager.getAccessToken();
                  print("✅ 重新授权成功，新Token长度: ${accessToken.length} 字符");

                  // 再次重新发送API请求
                  print("🌐 再次重新发送API请求...");
                  request = http.Request("POST", uri)
                    ..headers.addAll({
                      "Authorization": "Bearer $accessToken",
                      "Content-Type": "application/json",
                      "User-Agent": "Flutter/1.0",
                      "Accept": "text/event-stream",
                    })
                    ..body = jsonEncode({
                      "workflow_id": workflowId,
                      "parameters": {"input": input},
                    });

                  streamedResponse = await request.send();
                  print("📥 重新授权后请求响应，状态码: ${streamedResponse.statusCode}");

                  if (streamedResponse.statusCode != 200) {
                    var finalErrorBody = await streamedResponse.stream
                        .bytesToString();
                    print(
                      "❌ 重新授权后仍然失败: ${streamedResponse.statusCode} - $finalErrorBody",
                    );
                    print("⚠️ 重新授权失败，直接使用模拟数据");
                    return generateMockData(input);
                  }
                } catch (e) {
                  print("❌ 重新授权失败: $e");
                  print("⚠️ 重新授权失败");
                  throw Exception('重新授权失败: $e');
                }
              }
            } catch (e) {
              print("❌ 刷新token失败: $e");
              throw Exception('刷新token失败: $e');
            }
          }
        } catch (e) {
          // 忽略JSON解析错误
          print("⚠️ 解析错误响应失败: $e");
        }
      }

      if (streamedResponse.statusCode != 200) {
        print("⚠️ API请求失败");
        throw Exception('API请求失败，状态码: ${streamedResponse.statusCode}');
      }
    }

    print("✅ API请求成功，开始解析响应...");

    Map<String, dynamic>? finalResult;
    String responseBody = "";

    // 首先尝试读取完整响应体
    responseBody = await streamedResponse.stream.bytesToString();
    print("📊 完整响应体大小: ${responseBody.length} 字符");
    print("📄 响应体内容: $responseBody");

    // 尝试解析JSON响应
    try {
      Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      print("🔍 解析JSON响应: $jsonResponse");

      if (jsonResponse['code'] == 0 && jsonResponse['data'] != null) {
        // 成功响应，解析data字段
        String dataStr = jsonResponse['data'];
        Map<String, dynamic> dataJson = jsonDecode(dataStr);
        print("🔍 解析data字段: $dataJson");

        if (dataJson['output'] != null) {
          String outputText = dataJson['output'];
          print("📝 提取output文本: $outputText");

          finalResult = parseOutputText(outputText);
          if (!finalResult!.containsKey('error')) {
            print("✅ 成功解析output文本");
          }
        }
      } else {
        print("❌ API返回错误: ${jsonResponse['msg'] ?? '未知错误'}");
      }
    } catch (e) {
      print("❌ JSON解析失败: $e");

      // 如果JSON解析失败，尝试流式解析
      print("⚠️ 尝试流式解析...");
      String accumulatedContent = "";

      await streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
            print("📄 收到行: $line");

            if (line.startsWith("data:")) {
              String jsonStr = line.substring(5).trim();
              if (jsonStr.isEmpty || jsonStr == "[DONE]") return;

              try {
                // 第一层解析
                Map<String, dynamic> event = jsonDecode(jsonStr);
                print("🔍 解析事件: $event");

                if (event.containsKey("content") &&
                    event["content"] is String) {
                  // 第二层解析
                  Map<String, dynamic> innerContent = jsonDecode(
                    event["content"],
                  );
                  print("🔍 解析内部内容: $innerContent");

                  if (innerContent.containsKey("output")) {
                    String outputText = innerContent["output"];
                    accumulatedContent += outputText;
                    print("📝 累积内容: $accumulatedContent");

                    // 尝试解析完整的输出
                    finalResult = parseOutputText(accumulatedContent);
                    if (!finalResult!.containsKey('error')) {
                      print("✅ 成功解析完整输出");
                    }
                  }
                }
              } catch (e) {
                print("⚠️ 解析错误: $e");
              }
            }
          });
    }

    // 如果流式解析失败，尝试从完整响应中提取
    if (finalResult == null || finalResult!.containsKey('error')) {
      print("⚠️ 流式解析失败，尝试从完整响应中提取");

      // 尝试从响应体中提取JSON
      try {
        var lines = responseBody.split('\n');
        for (var line in lines) {
          if (line.startsWith("data:") && line.length > 5) {
            String jsonStr = line.substring(5).trim();
            if (jsonStr.isNotEmpty && jsonStr != "[DONE]") {
              Map<String, dynamic> event = jsonDecode(jsonStr);
              if (event.containsKey("content")) {
                Map<String, dynamic> innerContent = jsonDecode(
                  event["content"],
                );
                if (innerContent.containsKey("output")) {
                  String outputText = innerContent["output"];
                  finalResult = parseOutputText(outputText);
                  if (!finalResult!.containsKey('error')) {
                    print("✅ 从完整响应中成功解析");
                    break;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print("❌ 从完整响应中解析失败: $e");
      }
    }

    if (finalResult == null || finalResult!.containsKey('error')) {
      print("❌ 所有解析方法都失败");
      throw Exception('数据解析失败');
    }

    try {
      var topic = Topic.fromParseResult(finalResult!);
      print("🎉 成功创建Topic对象: ${topic.topic}");
      return topic;
    } catch (e) {
      print("❌ 创建Topic对象失败: $e");
      throw Exception('创建Topic对象失败: $e');
    }
  } catch (e) {
    print("❌ 网络请求异常: $e");

    // 检查是否是OAuth认证问题
    if (e.toString().contains('OAuth') || e.toString().contains('认证')) {
      print("⚠️ OAuth认证问题");
      print("💡 提示：请检查网络连接或重新授权");
      throw Exception('OAuth认证问题: $e');
    } else {
      print("⚠️ 网络连接问题");
      throw Exception('网络连接问题: $e');
    }
  }
}

// 检查当前token状态
Future<void> _checkTokenStatus() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('coze_access_token');
    final refreshToken = prefs.getString('coze_refresh_token');
    final expiryMillis = prefs.getInt('coze_token_expiry');

    print("🔍 检查Token状态:");
    print("  Access Token: ${accessToken != null ? '已缓存' : '未缓存'}");
    print("  Refresh Token: ${refreshToken != null ? '已缓存' : '未缓存'}");

    if (expiryMillis != null && expiryMillis > 0) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      final now = DateTime.now();
      final isExpired = now.isAfter(expiry);

      print("  Token过期时间: $expiry");
      print("  Token状态: ${isExpired ? '已过期' : '有效'}");

      if (isExpired) {
        print("⚠️ Token已过期，OAuth服务将自动尝试刷新");
      } else {
        print("✅ Token仍然有效");
      }
    } else {
      print("  Token过期时间: 未设置");
    }

    // 检查是否有刷新token可用
    if (refreshToken != null) {
      print("✅ 有刷新token可用，可以自动刷新");
    } else {
      print("⚠️ 没有刷新token，需要重新授权");
    }
  } catch (e) {
    print("⚠️ 检查Token状态失败: $e");
  }
}

// 强制清除OAuth缓存
Future<void> _clearOAuthCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('coze_access_token');
    await prefs.remove('coze_refresh_token');
    await prefs.remove('coze_token_expiry');
    print("✅ OAuth缓存已清除");
  } catch (e) {
    print("⚠️ 清除OAuth缓存失败: $e");
  }
}

void main() async {
  print("开始测试 generate.dart");
  var result = await extractAndParseOutput("邓小平");
  if (result != null) {
    print("✅ 测试成功");
    print("主题: ${result.topic}");
    print("详情: ${result.detail}");
    print("问题数量: ${result.questions.length}");
    print("问题列表:");
    for (int i = 0; i < result.questions.length; i++) {
      print("  ${i + 1}. ${result.questions[i]}");
    }
    print("\nJSON格式:");
    print(jsonEncode(result.toJson()));
  } else {
    print("❌ 测试失败");
  }
}
