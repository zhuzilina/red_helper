import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/pages/content_page/super_page/super_page.dart';

void main() {
  group('三个问题显示测试', () {
    testWidgets('验证三个问题完整显示', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '邓小平')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证问题概览标题
      expect(find.textContaining('我们将从以下三个问题进一步了解'), findsOneWidget);

      // 验证问题数量（应该显示3个问题）
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // 验证不需要滚动
      final listView = find.byType(ListView);
      expect(listView, findsNothing); // 应该没有ListView，因为使用Column布局
    });

    testWidgets('验证布局紧凑性', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '邓小平')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证所有内容都在一屏内显示
      final screenHeight =
          tester.binding.window.physicalSize.height /
          tester.binding.window.devicePixelRatio;
      final contentHeight = tester.getSize(find.byType(Column)).height;

      // 内容高度应该小于屏幕高度
      expect(contentHeight, lessThan(screenHeight));
    });
  });
}


