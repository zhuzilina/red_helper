import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_helper/pages/home_page/home_page.dart';
import 'package:red_helper/pages/learn_page/learn_page.dart';
import 'package:red_helper/pages/trip_page/trip_page.dart';
import 'package:red_helper/pages/user_page/user_page.dart';
import 'package:red_helper/pages/content_page/camera_page/camera_page.dart';
import 'package:red_helper/providers/msg_state.dart';
import 'package:red_helper/route/routes.dart';
import 'package:red_helper/providers/task_state.dart';
import 'package:red_helper/providers/points_state.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final appState;
  final List<Widget> _pages = [
    const HomePage(),
    const LearnPage(),
    const TripPage(),
    const UserPage(),
  ];
  bool _isInitialized = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // 只初始化一次
      appState = Provider.of<MsgState>(context);
      appState.loadMessages();
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 3
          ? null // 在用户页面隐藏AppBar
          : AppBar(
              title: Text(
                '薪传Π',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              actions: [
                _buildMsgButtonWithBadge(context),
                const SizedBox(width: 8),
              ],
            ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "首页",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: "文化",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.travel_explore_outlined),
                activeIcon: Icon(Icons.travel_explore),
                label: "旅游",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "我的",
              ),
            ],
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMsgButtonWithBadge(BuildContext context) {
    final theme = Theme.of(context);
    final taskState = Provider.of<TaskState>(context);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Image.asset('assets/images/points.png', fit: BoxFit.contain),
        ),
      ],
    );
  }

  Widget _buildRedeemButtonWithBadge(BuildContext context) {
    final theme = Theme.of(context);
    final pointsState = Provider.of<PointsState>(context);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: Image.asset(
            "assets/images/points.png",
            fit: BoxFit.fill,
            width: 48,
            height: 48,
          ),
          tooltip: '积分兑换',
          color: theme.colorScheme.onPrimary,
          onPressed: () => Navigator.pushNamed(context, RoutePath.exchange),
        ),
      ],
    );
  }
}

void _openCamera(BuildContext context) async {
  final cameras = await availableCameras();
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (ctx) => CameraPage(cameras: cameras)),
  );

  if (result != null) {
    // 处理拍摄结果
    File imageFile = File(result);
    // 显示预览或上传...
  }
}
