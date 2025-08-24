import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/pages/content_page/super_page/super_page.dart';

void main() {
  group('SuperPage问题解答功能测试', () {
    testWidgets('验证问题解答功能集成', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '焦裕禄')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证总览页面元素
      expect(find.text('主题总览'), findsOneWidget);
      expect(find.textContaining('我们将从以下三个问题进一步了解'), findsOneWidget);

      // 验证问题数量（应该显示3个问题）
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      print("✅ SuperPage问题解答功能测试通过");
    });

    testWidgets('验证页面导航功能', (WidgetTester tester) async {
      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '焦裕禄')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证页面指示器
      expect(find.textContaining('/'), findsOneWidget);

      // 验证菜单按钮存在
      expect(find.byIcon(Icons.menu), findsOneWidget);

      print("✅ 页面导航功能测试通过");
    });
  });
}


