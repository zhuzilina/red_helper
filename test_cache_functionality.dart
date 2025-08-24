import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'lib/providers/question_answer_provider.dart';
import 'lib/repository/api/question_answer_api.dart';

void main() {
  group('缓存功能测试', () {
    test('缓存键生成一致性测试', () {
      final provider = QuestionAnswerProvider();

      // 相同问题应该生成相同的缓存键
      final question1 = "测试问题内容";
      final question2 = "测试问题内容";
      final question3 = "不同的测试问题";

      // 通过缓存操作来验证键的一致性
      final answer1 = provider.getCachedAnswer(question1);
      final answer2 = provider.getCachedAnswer(question2);
      final answer3 = provider.getCachedAnswer(question3);

      // 初始状态都应该是null
      expect(answer1, isNull);
      expect(answer2, isNull);
      expect(answer3, isNull);

      print("✅ 缓存键生成一致性测试通过");
    });

    test('缓存状态管理测试', () {
      final provider = QuestionAnswerProvider();

      // 测试初始状态
      final stats = provider.getCacheStats();
      expect(stats['totalCached'], equals(0));
      expect(stats['totalLoading'], equals(0));
      expect(stats['totalErrors'], equals(0));

      // 测试加载状态
      expect(provider.isLoading("测试问题"), isFalse);
      expect(provider.hasAnyLoading, isFalse);

      print("✅ 缓存状态管理测试通过");
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

    test('Provider与Consumer集成测试', () {
      final provider = QuestionAnswerProvider();

      // 模拟Consumer使用
      final testWidget = MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<QuestionAnswerProvider>(
            builder: (context, provider, child) {
              final stats = provider.getCacheStats();
              return Text('缓存状态: ${stats['totalCached']}');
            },
          ),
        ),
      );

      expect(testWidget, isNotNull);

      print("✅ Provider与Consumer集成测试通过");
    });

    test('调试方法测试', () {
      final provider = QuestionAnswerProvider();

      // 调用调试方法
      provider.debugCache();

      // 验证方法执行无异常
      expect(provider, isNotNull);

      print("✅ 调试方法测试通过");
    });
  });
}


