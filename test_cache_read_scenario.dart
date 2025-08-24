import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'lib/providers/question_answer_provider.dart';
import 'lib/repository/api/question_answer_api.dart';

void main() {
  group('缓存读取场景测试', () {
    test('模拟缓存读取流程', () {
      final provider = QuestionAnswerProvider();

      // 模拟问题内容
      final question1 = "焦裕禄在兰考治理灾害时面临哪些具体困难？";
      final question2 = "焦裕禄在兰考治理灾害时面临哪些具体困难？"; // 相同问题
      final question3 = "焦裕禄是如何克服这些困难的？"; // 不同问题

      print("🔍 开始模拟缓存读取流程");

      // 第一次查询 - 应该返回null（无缓存）
      final answer1 = provider.getCachedAnswer(question1);
      expect(answer1, isNull);
      print("✅ 第一次查询返回null（无缓存）");

      // 检查加载状态
      final isLoading1 = provider.isLoading(question1);
      expect(isLoading1, isFalse);
      print("✅ 初始加载状态为false");

      // 检查缓存统计
      final stats1 = provider.getCacheStats();
      expect(stats1['totalCached'], equals(0));
      print("✅ 初始缓存数量为0");

      // 模拟相同问题的第二次查询
      final answer2 = provider.getCachedAnswer(question2);
      expect(answer2, isNull); // 仍然应该是null，因为还没有缓存
      print("✅ 相同问题的第二次查询仍然返回null");

      // 模拟不同问题的查询
      final answer3 = provider.getCachedAnswer(question3);
      expect(answer3, isNull);
      print("✅ 不同问题的查询返回null");

      // 打印调试信息
      provider.debugCache();

      print("✅ 缓存读取场景测试通过");
    });

    test('缓存键一致性验证', () {
      final provider = QuestionAnswerProvider();

      // 测试完全相同的问题
      final question1 = "测试问题";
      final question2 = "测试问题";

      // 生成缓存键（通过内部方法模拟）
      final key1 = _generateQuestionId(question1);
      final key2 = _generateQuestionId(question2);

      expect(key1, equals(key2));
      print("✅ 相同问题的缓存键一致: $key1");

      // 测试不同的问题
      final question3 = "不同的问题";
      final key3 = _generateQuestionId(question3);

      expect(key1, isNot(equals(key3)));
      print("✅ 不同问题的缓存键不同: $key1 vs $key3");

      print("✅ 缓存键一致性验证通过");
    });

    test('Provider状态更新测试', () {
      final provider = QuestionAnswerProvider();

      // 初始状态
      final initialStats = provider.getCacheStats();
      expect(initialStats['totalCached'], equals(0));

      // 模拟状态更新（通过清除缓存来触发notifyListeners）
      provider.clearCache();

      // 状态应该保持为0
      final finalStats = provider.getCacheStats();
      expect(finalStats['totalCached'], equals(0));

      print("✅ Provider状态更新测试通过");
    });
  });
}

// 模拟缓存键生成方法
String _generateQuestionId(String question) {
  return question.hashCode.toString();
}


