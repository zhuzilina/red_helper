import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/pages/content_page/super_page/super_page.dart';
import 'lib/pages/content_page/super_page/generate.dart';

void main() {
  group('SuperPage 优化测试', () {
    testWidgets('SuperPage 初始化测试', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '邓小平')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证页面标题
      expect(find.text('邓小平'), findsOneWidget);
    });

    test('generate.dart 移除测试数据测试', () async {
      // 测试当 workflowId 为空时抛出异常
      try {
        await extractAndParseOutput("测试主题");
        fail('应该抛出异常');
      } catch (e) {
        expect(e.toString(), contains('API配置不完整'));
      }
    });

    test('Token 状态检查测试', () async {
      // 这里可以添加 token 状态检查的单元测试
      // 由于涉及 SharedPreferences，需要 mock 或集成测试
      expect(true, isTrue); // 占位测试
    });
  });
}
