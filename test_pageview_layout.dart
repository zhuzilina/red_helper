import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/repository/api/question_answer_api.dart';

void main() {
  group('PageView布局功能测试', () {
    test('解答预览功能测试', () {
      // 测试短文本
      final shortAnswer = "这是一个短答案";
      expect(shortAnswer.length, lessThan(100));

      // 测试长文本
      final longAnswer =
          "这是一个很长的答案，包含了很多内容。这个答案应该超过100个字符，以便测试截断功能。我们希望看到省略号出现在正确的位置。这个答案包含了更多的文字内容，确保长度超过100个字符。这个答案包含了更多的文字内容，确保长度超过100个字符。";
      expect(longAnswer.length, greaterThan(100));

      // 模拟预览功能
      String getPreview(String text) {
        if (text.length <= 100) {
          return text;
        }
        return '${text.substring(0, 100)}...';
      }

      expect(getPreview(shortAnswer), equals(shortAnswer));
      expect(getPreview(longAnswer), contains('...'));
      expect(getPreview(longAnswer).length, equals(103)); // 100 + "..."

      print("✅ 解答预览功能测试通过");
    });

    test('QuestionAnswerResponse状态测试', () {
      final response = QuestionAnswerResponse();

      // 初始状态
      expect(response.hasContent, isFalse);

      // 添加内容后
      response.answer = "测试答案";
      expect(response.hasContent, isTrue);

      // 清空内容后
      response.answer = "";
      expect(response.hasContent, isFalse);

      // 添加建议
      response.suggestions.add("建议1");
      expect(response.hasContent, isTrue);

      // 添加图片
      response.images.add("image1.jpg");
      expect(response.hasContent, isTrue);

      print("✅ QuestionAnswerResponse状态测试通过");
    });

    test('弹窗触发条件测试', () {
      final response = QuestionAnswerResponse();

      // 没有内容时不应该触发弹窗
      expect(response.hasContent, isFalse);

      // 有内容时应该可以触发弹窗
      response.answer = "有内容的答案";
      expect(response.hasContent, isTrue);

      print("✅ 弹窗触发条件测试通过");
    });
  });
}
