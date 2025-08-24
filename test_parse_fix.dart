import 'dart:convert';
import 'lib/repository/models/topic.dart';

void main() async {
  print("🔍 开始测试解析修复...");

  // 模拟API返回的数据
  String mockApiResponse =
      '''{"code":0,"data":"{\\"output\\":\\"# 焦裕禄\\\\n焦裕禄是中国共产党的优秀党员，人民的好公仆。20世纪60年代，他任兰考县委书记，当时兰考饱受内涝、风沙、盐碱三害困扰。他不顾肝病折磨，带领兰考人民艰苦奋斗，努力改变兰考面貌，最终因肝癌病逝，其事迹和精神激励着无数人。\\\\n- 焦裕禄到兰考任职前有着怎样的工作经历和人生阅历？\\\\n- 焦裕禄在治理兰考内涝、风沙、盐碱三害时采取了哪些具体有效的措施？\\\\n- 焦裕禄与兰考当地百姓之间有哪些感人至深的故事？\\\\n- 焦裕禄的精神在不同历史时期是如何传承和发展的？\\\\n- 焦裕禄的事迹对当时的中国社会产生了怎样的影响？ \\"}","debug_url":"https://www.coze.cn/work_flow?execute_id=7537543392932151331&space_id=7511155281058217995&workflow_id=7536844432798629907&execute_mode=2","msg":"Success","usage":{"input_count":202,"output_count":164,"token_count":366}}''';

  try {
    print("\n📝 测试1: 解析API响应");
    Map<String, dynamic> jsonResponse = jsonDecode(mockApiResponse);
    print("✅ JSON解析成功");
    print("  code: ${jsonResponse['code']}");
    print("  msg: ${jsonResponse['msg']}");

    if (jsonResponse['code'] == 0 && jsonResponse['data'] != null) {
      String dataStr = jsonResponse['data'];
      Map<String, dynamic> dataJson = jsonDecode(dataStr);
      print("✅ data字段解析成功");

      if (dataJson['output'] != null) {
        String outputText = dataJson['output'];
        print("✅ output文本提取成功");
        print("  文本长度: ${outputText.length} 字符");
        print(
          "  文本预览: ${outputText.substring(0, outputText.length > 100 ? 100 : outputText.length)}...",
        );

        // 测试解析output文本
        print("\n📝 测试2: 解析output文本");
        var result = parseOutputText(outputText);

        if (!result.containsKey('error')) {
          print("✅ output文本解析成功");
          print("  主题: ${result['topic']}");
          print("  详情: ${result['detail']}");
          print("  问题数量: ${result['questions'].length}");

          // 测试创建Topic对象
          print("\n📝 测试3: 创建Topic对象");
          var topic = Topic.fromParseResult(result);
          print("✅ Topic对象创建成功");
          print("  主题: ${topic.topic}");
          print("  详情: ${topic.detail}");
          print("  问题数量: ${topic.questions.length}");
          print("  问题列表:");
          for (int i = 0; i < topic.questions.length; i++) {
            print("    ${i + 1}. ${topic.questions[i]}");
          }
        } else {
          print("❌ output文本解析失败: ${result['error']}");
        }
      } else {
        print("❌ 未找到output字段");
      }
    } else {
      print("❌ API返回错误: ${jsonResponse['msg'] ?? '未知错误'}");
    }

    print("\n🎉 所有测试完成");
  } catch (e) {
    print("❌ 测试过程中发生异常: $e");
  }
}

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



