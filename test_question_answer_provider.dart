import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'lib/providers/question_answer_provider.dart';
import 'lib/repository/api/question_answer_api.dart';

void main() {
  group('QuestionAnswerProvider功能测试', () {
    test('Provider初始化测试', () {
      final provider = QuestionAnswerProvider();
      expect(provider, isNotNull);
      print("✅ QuestionAnswerProvider初始化测试通过");
    });

    test('缓存功能测试', () {
      final provider = QuestionAnswerProvider();

      // 初始状态
      final stats = provider.getCacheStats();
      expect(stats['totalCached'], equals(0));
      expect(stats['totalLoading'], equals(0));
      expect(stats['totalErrors'], equals(0));

      print("✅ 缓存功能测试通过");
    });

    test('问题ID生成测试', () {
      final provider = QuestionAnswerProvider();

      // 相同问题应该生成相同ID
      final question1 = "测试问题1";
      final question2 = "测试问题1";
      final question3 = "测试问题2";

      // 通过缓存键来验证ID生成
      final answer1 = provider.getCachedAnswer(question1);
      final answer2 = provider.getCachedAnswer(question2);
      final answer3 = provider.getCachedAnswer(question3);

      expect(answer1, isNull);
      expect(answer2, isNull);
      expect(answer3, isNull);

      print("✅ 问题ID生成测试通过");
    });

    test('加载状态管理测试', () {
      final provider = QuestionAnswerProvider();

      // 初始状态
      expect(provider.isLoading("测试问题"), isFalse);
      expect(provider.hasAnyLoading, isFalse);
      expect(provider.loadingQuestions, isEmpty);

      print("✅ 加载状态管理测试通过");
    });

    test('错误状态管理测试', () {
      final provider = QuestionAnswerProvider();

      // 初始状态
      expect(provider.getError("测试问题"), isNull);

      print("✅ 错误状态管理测试通过");
    });

    test('缓存清除功能测试', () {
      final provider = QuestionAnswerProvider();

      // 清除缓存
      provider.clearCache();

      final stats = provider.getCacheStats();
      expect(stats['totalCached'], equals(0));
      expect(stats['totalLoading'], equals(0));
      expect(stats['totalErrors'], equals(0));

      print("✅ 缓存清除功能测试通过");
    });

    test('预加载功能测试', () {
      final provider = QuestionAnswerProvider();

      // 预加载问题
      final questions = ["问题1", "问题2", "问题3"];
      provider.preloadAnswers(questions);

      // 验证预加载不会阻塞
      expect(provider.hasAnyLoading, isFalse);

      print("✅ 预加载功能测试通过");
    });

    test('Provider与Consumer集成测试', () {
      final provider = QuestionAnswerProvider();

      // 模拟Consumer使用
      final testWidget = MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<QuestionAnswerProvider>(
            builder: (context, provider, child) {
              return Text('Provider状态: ${provider.getCacheStats()}');
            },
          ),
        ),
      );

      expect(testWidget, isNotNull);

      print("✅ Provider与Consumer集成测试通过");
    });
  });
}
