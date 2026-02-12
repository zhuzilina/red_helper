import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/repository/api/question_answer_api.dart';
import 'lib/pages/coze_page/o_auth_service.dart';

void main() {
  group('问题解答API简单测试', () {
    test('测试QuestionAnswerResponse类', () {
      final response = QuestionAnswerResponse();

      // 初始状态
      expect(response.answer, isEmpty);
      expect(response.suggestions, isEmpty);
      expect(response.images, isEmpty);
      expect(response.isCompleted, isFalse);
      expect(response.hasContent, isFalse);

      // 添加内容
      response.answer = "这是一个测试答案";
      response.suggestions.add("建议1");
      response.images.add("https://example.com/image.jpg");

      // 验证状态
      expect(response.answer, isNotEmpty);
      expect(response.suggestions, hasLength(1));
      expect(response.images, hasLength(1));
      expect(response.hasContent, isTrue);

      print("✅ QuestionAnswerResponse测试通过");
    });

    test('测试OAuth服务初始化', () {
      final oAuthService = OAuthService();
      expect(oAuthService, isNotNull);
      print("✅ OAuth服务初始化测试通过");
    });

    test('测试问题解答服务初始化', () {
      final oAuthService = OAuthService();
      final questionAnswerService = QuestionAnswerService(oAuthService);
      expect(questionAnswerService, isNotNull);
      print("✅ 问题解答服务初始化测试通过");
    });
  });
}


