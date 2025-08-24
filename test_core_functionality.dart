import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/repository/api/question_answer_api.dart';
import 'lib/pages/coze_page/o_auth_service.dart';
import 'lib/env.dart';

void main() {
  group('核心功能测试', () {
    test('QuestionAnswerResponse功能测试', () {
      final response = QuestionAnswerResponse();

      // 初始状态测试
      expect(response.answer, isEmpty);
      expect(response.suggestions, isEmpty);
      expect(response.images, isEmpty);
      expect(response.isCompleted, isFalse);
      expect(response.hasContent, isFalse);

      // 添加内容测试
      response.answer = "这是一个详细的解答内容";
      response.suggestions.add("建议问题1");
      response.suggestions.add("建议问题2");
      response.images.add("https://example.com/image1.jpg");
      response.images.add("https://example.com/image2.jpg");
      response.isCompleted = true;

      // 验证状态
      expect(response.answer, "这是一个详细的解答内容");
      expect(response.suggestions, hasLength(2));
      expect(response.images, hasLength(2));
      expect(response.isCompleted, isTrue);
      expect(response.hasContent, isTrue);

      // 测试toString方法
      final stringRepresentation = response.toString();
      expect(stringRepresentation, contains("11字符"));
      expect(stringRepresentation, contains("2个"));
      expect(stringRepresentation, contains("true"));

      print("✅ QuestionAnswerResponse功能测试通过");
    });

    test('OAuth服务初始化测试', () {
      final oAuthService = OAuthService();
      expect(oAuthService, isNotNull);
      print("✅ OAuth服务初始化测试通过");
    });

    test('问题解答服务初始化测试', () {
      final oAuthService = OAuthService();
      final questionAnswerService = QuestionAnswerService(oAuthService);
      expect(questionAnswerService, isNotNull);
      print("✅ 问题解答服务初始化测试通过");
    });

    test('环境配置测试', () {
      // 验证环境配置中的常量存在
      expect(questionBotId, isNotEmpty);
      expect(questionClientId, isNotEmpty);
      print("✅ 环境配置测试通过");
      print("  questionBotId: $questionBotId");
      print("  questionClientId: $questionClientId");
    });
  });
}
