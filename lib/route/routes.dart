import 'package:flutter/material.dart';
import 'package:red_helper/main_screen.dart';
import 'package:red_helper/pages/auth_page/forgot_password.dart';
import 'package:red_helper/pages/auth_page/login_page.dart';
import 'package:red_helper/pages/auth_page/register_page.dart';
import 'package:red_helper/pages/content_page/reward_page/reward_exchange_page.dart';
import 'package:red_helper/pages/content_page/reward_page/reward_task_page.dart';
import 'package:red_helper/pages/content_page/ai_page/ai_page.dart';
import 'package:red_helper/pages/content_page/message_page/message_page.dart';

import '../pages/content_page/question/question.dart';

class Routers {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutePath.main:
        return _fadeRoute(MainScreen(), settings);
      case RoutePath.login:
        return _fadeRoute(LoginPage(), settings);
      case RoutePath.register:
        return _fadeRoute(RegisterPage(), settings);
      case RoutePath.task:
        return _fadeRoute(TaskPage(), settings);
      case RoutePath.exchange:
        return _fadeRoute(RewardExchangePage(), settings);
      case RoutePath.assistant:
        return _fadeRoute(AIPage(arguments: settings.arguments), settings);
      case RoutePath.message:
        return _fadeRoute(MessagePage(arguments: settings.arguments), settings);
      // 内容板块
      case RoutePath.question:
        return _fadeRoute(DailyQuizPage(title: null), settings);
      case RoutePath.forgotPassword:
        return _fadeRoute(ForgotPassword(), settings);
      default:
        return _errorRoute(settings);
    }
  }

  // 渐变动画路由
  static PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // 错误路由处理
  static MaterialPageRoute _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) =>
          Scaffold(body: Center(child: Text('未找到路由: ${settings.name}'))),
    );
  }
}

class RoutePath {
  // 主屏幕
  static const String main = "/main";
  // 首页
  static const String home = "/home";
  // 学习
  static const String learn = "/learn";
  // 登录
  static const String login = "/login";
  // 注册
  static const String register = "/register";
  // 忘记密码
  static const String forgotPassword = "/forgotPassword";
  // 任务
  static const String task = "/task";
  // 兑换
  static const String exchange = "/exchange";
  // 智能助手
  static const String assistant = "/assistant";
  // 消息页面
  static const String message = "/message";
  // 内容页面
  // 答题页面
  static const String question = "/question";
}
