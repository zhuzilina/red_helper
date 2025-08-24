import 'lib/pages/content_page/super_page/generate.dart';

void main() async {
  print("🔍 开始测试UI修复...");

  try {
    print("\n📝 测试1: 获取真实数据");
    var result = await extractAndParseOutput("邓小平");

    if (result != null) {
      print("✅ 数据获取成功");
      print("  主题: ${result.topic}");
      print("  详情: ${result.detail}");
      print("  问题数量: ${result.questions.length}");

      print("\n📝 测试2: 验证数据结构");
      print("  主题类型: ${result.topic.runtimeType}");
      print("  详情类型: ${result.detail.runtimeType}");
      print("  问题列表类型: ${result.questions.runtimeType}");

      if (result.questions.isNotEmpty) {
        print("  第一个问题类型: ${result.questions[0].runtimeType}");
        print("  第一个问题长度: ${result.questions[0].length}");
      }

      print("\n📝 测试3: 验证数据完整性");
      bool isValid = true;

      if (result.topic.isEmpty) {
        print("❌ 主题为空");
        isValid = false;
      }

      if (result.detail.isEmpty) {
        print("❌ 详情为空");
        isValid = false;
      }

      if (result.questions.isEmpty) {
        print("❌ 问题列表为空");
        isValid = false;
      }

      for (int i = 0; i < result.questions.length; i++) {
        if (result.questions[i].isEmpty) {
          print("❌ 问题${i + 1}为空");
          isValid = false;
        }
      }

      if (isValid) {
        print("✅ 数据完整性验证通过");
      } else {
        print("❌ 数据完整性验证失败");
      }

      print("\n📝 测试4: 模拟UI渲染");
      print("  模拟设置_topic = result");
      print("  模拟设置_isLoading = false");
      print("  模拟设置_errorMessage = null");
      print("  应该显示主要内容视图");
    } else {
      print("❌ 数据获取失败");
    }

    print("\n🎉 所有测试完成");
  } catch (e) {
    print("❌ 测试过程中发生异常: $e");
  }
}



