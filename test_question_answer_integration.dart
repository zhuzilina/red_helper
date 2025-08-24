import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/pages/content_page/super_page/super_page.dart';
import 'lib/repository/api/question_answer_api.dart';
import 'lib/pages/coze_page/o_auth_service.dart';

void main() {
  group('问题解答功能集成测试', () {
    testWidgets('SuperPage基本功能测试', (WidgetTester tester) async {
      // 初始化Flutter绑定
      TestWidgetsFlutterBinding.ensureInitialized();

      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '焦裕禄')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证基本元素存在
      expect(find.text('焦裕禄'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      print("✅ SuperPage基本功能测试通过");
    });

    testWidgets('问题解答服务集成测试', (WidgetTester tester) async {
      // 初始化Flutter绑定
      TestWidgetsFlutterBinding.ensureInitialized();

      // 创建服务实例
      final oAuthService = OAuthService();
      final questionAnswerService = QuestionAnswerService(oAuthService);

      // 验证服务创建成功
      expect(questionAnswerService, isNotNull);

      // 测试响应数据模型
      final response = QuestionAnswerResponse();
      expect(response.hasContent, isFalse);

      // 模拟添加内容
      response.answer = "测试解答内容";
      response.suggestions.add("测试建议");
      response.images.add("https://example.com/test.jpg");

      expect(response.hasContent, isTrue);
      expect(response.answer, "测试解答内容");
      expect(response.suggestions, hasLength(1));
      expect(response.images, hasLength(1));

      print("✅ 问题解答服务集成测试通过");
    });

    testWidgets('页面导航功能测试', (WidgetTester tester) async {
      // 初始化Flutter绑定
      TestWidgetsFlutterBinding.ensureInitialized();

      // 构建 SuperPage widget
      await tester.pumpWidget(MaterialApp(home: SuperPage(topicName: '焦裕禄')));

      // 等待widget构建完成
      await tester.pumpAndSettle();

      // 验证页面指示器存在
      expect(find.textContaining('/'), findsOneWidget);

      // 验证菜单按钮可点击
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);

      // 点击菜单按钮
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      print("✅ 页面导航功能测试通过");
    });

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
  });
}
