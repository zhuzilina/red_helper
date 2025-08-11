import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiToken = "cztei_l9K********";
const String workflowId = "7536*****";

/// 解析 output 文本为结构化 JSON
Map<String, dynamic> parseOutputText(String text) {
  try {
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

    return {"topic": topic, "detail": detail, "questions": questions};
  } catch (e) {
    print("文本解析错误: $e");
    return {"error": e.toString()};
  }
}

/// 从流中提取并解析 output
Future<Map<String, dynamic>> extractAndParseOutput(String input) async {
  var uri = Uri.parse("https://api.coze.cn/v1/workflow/stream_run");
  var request = http.Request("POST", uri)
    ..headers.addAll({
      "Authorization": "Bearer $apiToken",
      "Content-Type": "application/json",
    })
    ..body = jsonEncode({
      "workflow_id": workflowId,
      "parameters": {"input": input},
    });

  var streamedResponse = await request.send();

  Map<String, dynamic>? finalResult;

  await streamedResponse.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
        if (line.startsWith("data:")) {
          String jsonStr = line.substring(5).trim();
          if (jsonStr.isEmpty || jsonStr == "[DONE]") return;

          try {
            // 第一层解析
            Map<String, dynamic> event = jsonDecode(jsonStr);

            if (event.containsKey("content") && event["content"] is String) {
              // 第二层解析
              Map<String, dynamic> innerContent = jsonDecode(event["content"]);

              if (innerContent.containsKey("output")) {
                String outputText = innerContent["output"];
                finalResult = parseOutputText(outputText);
              }
            }
          } catch (e) {
            print("⚠️ 解析错误: $e");
          }
        }
      });

  return finalResult ?? {"error": "未获取到有效数据"};
}

void main() async {
  var result = await extractAndParseOutput("邓小平");
  print(jsonEncode(result)); // 直接以 JSON 格式打印
}
