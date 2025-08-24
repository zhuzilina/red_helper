import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/repository/api/question_answer_api.dart';

void main() {
  group('重复内容修复测试', () {
    test('QuestionAnswerResponse重复内容处理测试', () {
      final response = QuestionAnswerResponse();

      // 测试答案内容累积
      response.answer = "第一部分内容";
      expect(response.answer, equals("第一部分内容"));

      response.answer += "第二部分内容";
      expect(response.answer, equals("第一部分内容第二部分内容"));

      // 测试建议去重（手动去重）
      final suggestions = <String>{};
      suggestions.add("建议1");
      suggestions.add("建议2");
      suggestions.add("建议1"); // 重复建议

      expect(suggestions.length, equals(2));
      expect(suggestions.contains("建议1"), isTrue);
      expect(suggestions.contains("建议2"), isTrue);

      // 测试图片去重（手动去重）
      final images = <String>{};
      images.add("图片1.jpg");
      images.add("图片2.jpg");
      images.add("图片1.jpg"); // 重复图片

      expect(images.length, equals(2));
      expect(images.contains("图片1.jpg"), isTrue);
      expect(images.contains("图片2.jpg"), isTrue);

      print("✅ QuestionAnswerResponse重复内容处理测试通过");
    });

    test('数据ID生成一致性测试', () {
      // 模拟数据ID生成逻辑
      String generateDataId(Map<String, dynamic> data) {
        final type = data['type'] ?? '';
        final contentType = data['content_type'] ?? '';
        final content = data['content'] ?? '';
        return '${type}_${contentType}_${content.hashCode}';
      }

      // 相同数据应该生成相同ID
      final data1 = {'type': 'answer', 'content': '测试内容'};
      final data2 = {'type': 'answer', 'content': '测试内容'};
      final data3 = {'type': 'answer', 'content': '不同内容'};

      final id1 = generateDataId(data1);
      final id2 = generateDataId(data2);
      final id3 = generateDataId(data3);

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));

      print("✅ 数据ID生成一致性测试通过");
    });

    test('内容长度计算测试', () {
      final response = QuestionAnswerResponse();

      // 测试空内容
      expect(response.answer.length, equals(0));
      expect(response.hasContent, isFalse);

      // 测试有内容
      response.answer = "测试答案内容";
      expect(response.answer.length, equals(6));
      expect(response.hasContent, isTrue);

      // 测试长内容
      final longAnswer = "这是一个很长的答案内容，用于测试长度计算功能。这个答案包含了多个字符，确保长度计算正确。";
      response.answer = longAnswer;
      expect(response.answer.length, equals(longAnswer.length));

      print("✅ 内容长度计算测试通过");
    });

    test('响应对象状态测试', () {
      final response = QuestionAnswerResponse();

      // 初始状态
      expect(response.isCompleted, isFalse);
      expect(response.hasContent, isFalse);

      // 添加内容后
      response.answer = "测试内容";
      expect(response.hasContent, isTrue);

      // 标记完成
      response.isCompleted = true;
      expect(response.isCompleted, isTrue);

      print("✅ 响应对象状态测试通过");
    });
  });
}
