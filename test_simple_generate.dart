import 'lib/pages/content_page/super_page/generate.dart';

void main() async {
  print("🔍 开始测试generate.dart修复...");

  try {
    print("\n📝 测试1: 使用模拟数据");
    var result1 = await extractAndParseOutput("测试主题");
    if (result1 != null) {
      print("✅ 测试1成功");
      print("  主题: ${result1.topic}");
      print("  详情: ${result1.detail}");
      print("  问题数量: ${result1.questions.length}");
    } else {
      print("❌ 测试1失败");
    }

    print("\n📝 测试2: 使用真实API（可能失败）");
    var result2 = await extractAndParseOutput("焦裕禄");
    if (result2 != null) {
      print("✅ 测试2成功");
      print("  主题: ${result2.topic}");
      print("  详情: ${result2.detail}");
      print("  问题数量: ${result2.questions.length}");
    } else {
      print("❌ 测试2失败");
    }

    print("\n📝 测试3: 使用另一个主题");
    var result3 = await extractAndParseOutput("邓小平");
    if (result3 != null) {
      print("✅ 测试3成功");
      print("  主题: ${result3.topic}");
      print("  详情: ${result3.detail}");
      print("  问题数量: ${result3.questions.length}");
    } else {
      print("❌ 测试3失败");
    }

    print("\n🎉 所有测试完成");
  } catch (e) {
    print("❌ 测试过程中发生异常: $e");
  }
}



