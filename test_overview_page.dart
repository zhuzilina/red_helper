import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/pages/content_page/super_page/super_page.dart';

void main() {
  group('总览页面测试', () {
    testWidgets('总览页面显示测试', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '邓小平')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证总览页面元素
      expect(find.text('主题总览'), findsOneWidget);
      expect(find.text('了解主题内容和问题概览'), findsOneWidget);
      expect(find.text('主题介绍'), findsOneWidget);
      expect(find.textContaining('我们将从以下三个问题进一步了解'), findsOneWidget);
      expect(find.text('向上滑动查看详细问题'), findsOneWidget);
    });

    testWidgets('页面导航测试', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '邓小平')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证页面指示器显示正确的页面数量
      expect(find.textContaining('/'), findsOneWidget);
    });

    testWidgets('抽屉菜单测试', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '邓小平')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 点击菜单按钮
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // 验证抽屉中的总览页面选项
      expect(find.text('主题总览'), findsOneWidget);
      expect(find.text('页面目录'), findsOneWidget);
    });
  });
}
