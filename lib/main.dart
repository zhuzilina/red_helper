import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_helper/providers/msg_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:red_helper/main_screen.dart';
import 'package:red_helper/pages/auth_page/login_page.dart';
import 'package:red_helper/repository/api/api.dart';
import 'package:red_helper/route/routes.dart';
import 'package:red_helper/utils/global_oauth_manager.dart';
import 'providers/task_state.dart';
import 'providers/points_state.dart';
import 'providers/question_answer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局OAuth管理器
  final oAuthManager = GlobalOAuthManager();
  await oAuthManager.initialize();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskState()),
        Provider<ApiService>(create: (_) => ApiService(token)),
        ChangeNotifierProxyProvider<ApiService, PointsState>(
          create: (context) => PointsState(context.read<ApiService>()),
          update: (_, apiService, pointsState) =>
              pointsState ?? PointsState(apiService),
        ),
        ChangeNotifierProvider(create: (_) => MsgState()),
        ChangeNotifierProvider(create: (_) => QuestionAnswerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xffBA0C2F)),
      ),
      onGenerateRoute: Routers.generateRoute,
      home: AuthWrapper(), // 修改初始页面为启动页
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();
    return apiService.token.isNotEmpty ? const MainScreen() : const LoginPage();
    // return MainScreen();
  }
}
