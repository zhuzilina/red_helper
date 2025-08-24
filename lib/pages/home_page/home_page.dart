// 导入flutter组件
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// 导入服务组件
import 'package:red_helper/route/routes.dart';
import 'package:red_helper/repository/api/api.dart';
import 'package:red_helper/repository/models/model.dart';
import 'package:red_helper/repository/api/api_kits.dart';
import 'package:red_helper/api_exception/api_exception.dart';
// 导入widget组件
import 'widget/section_title/section_title.dart';
import 'widget/friend_ranking/friend_ranking_card.dart';
import 'widget/points_distribution/distribution_chart.dart';
import 'widget/status/login_prompt.dart';
import 'widget/status/loading_indicator.dart';
import 'widget/status/error_retry.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 处理登录状态
  bool _isLogin = false;
  String token = '';
  // 处理好友排行数据
  List<Friend> _friends = [];
  bool _isLoading = false;
  String _errorMessage = '';
  // 处理积分分布数据
  List<PointsCategory> _categories = [];
  bool _isCategoriesLoading = false;
  String _categoriesError = '';
  // 网络连接状态
  bool _hasNetworkConnection = true;
  // 处理地图板块
  // 气泡
  List<String> pops = [
    "瑞金历史悠久，是红色故都，当年中央苏区文化的中心。",
    "湘江战役纪念馆：踏血湘江，铭记不朽英雄魂",
    "黎平会议旧址：黎平定策，红色曙光耀征程",
    "遵义会议会址：遵义转折，领航革命新方向",
    "铁索寒中，飞夺泸定铸传奇",
    "四渡赤水，神笔挥就战争奇章",
    "彝海结盟，民族团结谱新章",
  ];
  // 显示逻辑
  int currentVisible = 0;
  // 定时器
  late Timer _timer;
  // 处理运动状态
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  final String _status = '?';
  late final int _steps = 0;
  final num height = 1.7;
  final num weight = 55;
  late num distance = (_steps * (height * 0.45)) / 1000;
  late num calorie = weight * distance * 0.77;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkNetworkConnection();
      await _checkAuthentication();
      if (_isLogin && _hasNetworkConnection) {
        await _loadFriendRanking();
        await _loadPointsDistribution();
      }
    });
    _startAutoSwitch(); // 自动气泡
    //initPlatformState(); // 初始化步数获取
  }

  // 检查网络连接状态
  Future<void> _checkNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      if (!mounted) return; // 提前检查mounted状态

      setState(() => _hasNetworkConnection = hasConnection);

      if (!hasConnection) {
        if (mounted) {
          setState(() {
            _errorMessage = '网络连接不可用，请检查网络设置';
            _categoriesError = '网络连接不可用，请检查网络设置';
          });
        }
      }
    } catch (e) {
      // 如果无法检查网络状态，假设有网络连接
      if (mounted) {
        setState(() => _hasNetworkConnection = true);
      }
    }
  }

  void _startAutoSwitch() {
    _timer = Timer.periodic(
      const Duration(seconds: 10), // 6秒间隔
      (Timer timer) {
        if (mounted) {
          _switchContent();
        } else {
          timer.cancel(); // 如果组件已销毁，取消定时器
        }
      },
    );
  }

  void _switchContent() {
    if (mounted) {
      setState(() {
        currentVisible = (currentVisible + 1) % 6; // 循环切换
      });
    }
  }

  // void onStepCount(StepCount event) {
  //   setState(() {
  //     _steps = event.steps;
  //     distance = (_steps * (height * 0.45)) / 1000;
  //     calorie = weight * distance * 0.77;
  //   });
  // }

  // void onPedestrianStatusChanged(PedestrianStatus event) {
  //   setState(() {
  //     _status = event.status;
  //   });
  // }

  // void onPedestrianStatusError(error) {
  //   print('获取步数失败: $error');
  //   setState(() {
  //     _status = 'Pedestrian Status not available';
  //   });
  //   print(_status);
  // }

  // void onStepCountError(error) {
  //   print('onStepCountError: $error');
  //   setState(() {
  //     _steps = -1;
  //   });
  // }

  Future<bool> _checkAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final isAuthenticated = token.isNotEmpty;

      if (mounted) {
        setState(() => _isLogin = isAuthenticated);
      }

      if (!isAuthenticated) {
        if (mounted) {
          setState(() {
            _errorMessage = '请先登录';
            _friends = [];
            _categories = [];
          });
        }
      }
      return isAuthenticated;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '认证状态检查失败';
          _isLogin = false;
        });
      }
      return false;
    }
  }

  Future<void> _loadFriendRanking() async {
    if (!await _checkAuthentication()) return;
    if (!_hasNetworkConnection) {
      if (mounted) {
        setState(() {
          _errorMessage = '网络连接不可用，请检查网络设置';
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      // 每次请求前获取最新token
      final currentToken = await loadToken();
      print('🔍 开始加载积分排行数据...');
      print('🔑 当前Token: ${currentToken.substring(0, 20)}...');

      final ranking = await ApiService(currentToken).getFriendRanking();
      print('✅ 积分排行数据加载成功，数量: ${ranking.length}');
      print(
        '📊 排行数据: ${ranking.map((f) => '${f.nikename}: ${f.points}分').join(', ')}',
      );

      if (mounted) {
        setState(() {
          _friends = ranking;
          _isLoading = false;
          _errorMessage = '';
        });
        print('🔄 积分排行状态已更新');
      }
    } on ApiException catch (e) {
      // 处理认证失败情况
      if (e.statusCode == 401) {
        await _logout();
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '数据加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPointsDistribution() async {
    if (!await _checkAuthentication()) return;
    if (!_hasNetworkConnection) {
      if (mounted) {
        setState(() {
          _categoriesError = '网络连接不可用，请检查网络设置';
          _isCategoriesLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isCategoriesLoading = true);
    }
    try {
      final currentToken = await loadToken();
      print('🔍 开始加载积分分布数据...');

      final data = await ApiService(currentToken).getPointsDistribution();
      print('✅ 积分分布数据加载成功，数量: ${data.length}');
      print(
        '📊 分布数据: ${data.map((c) => '${c.category}: ${c.points}分').join(', ')}',
      );

      if (mounted) {
        setState(() {
          _categories = data;
          _isCategoriesLoading = false;
          _categoriesError = '';
        });
        print('🔄 积分分布状态已更新');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _logout();
      }
      if (mounted) {
        setState(() {
          _categoriesError = e.message;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesError = '图表加载失败，请稍后重试';
          _isCategoriesLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      if (mounted) {
        setState(() {
          _isLogin = false;
          token = '';
          _friends = [];
          _categories = [];
        });
      }
    } catch (e) {
      // 忽略登出时的异常
    }
  }

  // Future<bool> _checkActivityRecognitionPermission() async {
  //   bool granted = await Permission.activityRecognition.isGranted;

  //   if (!granted) {
  //     granted =
  //         await Permission.activityRecognition.request() ==
  //         PermissionStatus.granted;
  //   }

  //   return granted;
  // }

  // Future<void> initPlatformState() async {
  //   bool granted = await _checkActivityRecognitionPermission();
  //   if (!granted) {
  //     // tell user, the app will not work
  //   }

  //   _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
  //   (await _pedestrianStatusStream.listen(
  //     onPedestrianStatusChanged,
  //   )).onError(onPedestrianStatusError);

  //   _stepCountStream = Pedometer.stepCountStream;
  //   _stepCountStream.listen(onStepCount).onError(onStepCountError);

  //   if (!mounted) return;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 380,
              width: 380,
              child: Image.asset(
                'assets/images/home_map.jpg',
                fit: BoxFit.cover,
              ),
            ),
            _buildSportStatusCard(),
            Row(children: [SectionTitle("积分排行")]),
            _buildRankingSection(),
            _buildDistributionSection(),
          ],
        ),
      ),
    );
  }

  // 好友排行榜
  Widget _buildRankingSection() {
    if (!_isLogin) {
      return LoginPrompt(
        onLoginPressed: () => Navigator.pushNamed(context, RoutePath.login),
      );
    }
    if (!_hasNetworkConnection) {
      return ErrorRetry(
        message: '网络连接不可用，请检查网络设置',
        onRetry: () async {
          await _checkNetworkConnection();
          if (_hasNetworkConnection) {
            await _loadFriendRanking();
          }
        },
      );
    }
    if (_isLoading) return const LoadingIndicator();
    if (_errorMessage.isNotEmpty) {
      return ErrorRetry(message: _errorMessage, onRetry: _loadFriendRanking);
    }
    return FriendRankingCard(friends: _friends);
  }

  // 积分分布饼图
  Widget _buildDistributionSection() {
    if (!_isLogin) {
      return LoginPrompt(
        onLoginPressed: () => Navigator.pushNamed(context, RoutePath.login),
      );
    }
    if (!_hasNetworkConnection) {
      return ErrorRetry(
        message: '网络连接不可用，请检查网络设置',
        onRetry: () async {
          await _checkNetworkConnection();
          if (_hasNetworkConnection) {
            await _loadPointsDistribution();
          }
        },
        height: 260,
      );
    }
    if (_isCategoriesLoading) return const LoadingIndicator(height: 260);
    if (_categoriesError.isNotEmpty) {
      return ErrorRetry(
        message: _categoriesError,
        onRetry: _loadPointsDistribution,
        height: 260,
      );
    }
    return PointsDistributionChart(categories: _categories);
  }

  Widget _buildSportStatusCard() {
    // 模拟数据
    final mockData = {
      'steps': _steps,
      'calories': calorie,
      'duration': 15,
      'distance': distance,
    };

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.transparent, // 必须设置为透明以显示渐变
      shadowColor: Colors.transparent, // 移除默认阴影颜色
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xeef5eede), Color(0xaaf1c385)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.9],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🏃 今日运动状态",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 修改文字颜色为白色
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSportMetric(
                    Icons.directions_walk,
                    "3000",
                    "步",
                  ), //${mockData['duration']}
                  _buildSportMetric(Icons.local_fire_department, "100", "千卡"),
                  _buildSportMetric(Icons.timer, "12", "分钟"),
                  _buildSportMetric(Icons.alt_route, "4", "公里"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建运动指标组件
  Widget _buildSportMetric(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel(); // 组件销毁时取消定时器
    super.dispose();
  }
}

class PopBox extends StatefulWidget {
  // 自定义气泡弹窗
  final BuildContext context;
  final List<String> pops;
  final int currentVisible;

  const PopBox({
    super.key,
    required this.context,
    required this.pops,
    required this.currentVisible,
  });

  @override
  _PopBoxState createState() => _PopBoxState();
}

class _PopBoxState extends State<PopBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(PopBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当关键数据变化时触发动画
    if (oldWidget.currentVisible != widget.currentVisible) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: _buildContent());
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              widget.pops[widget.currentVisible],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                widget.context,
                RoutePath.assistant,
                arguments: {'prompt': '请以小红书文案的形式为我解读'},
              );
            },
            child: const SizedBox(
              width: 118,
              child: Text(
                '点击了解详情',
                style: TextStyle(fontSize: 14, color: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget popBox(BuildContext context, List<String> pops, int currentVisible) {
  return PopBox(context: context, pops: pops, currentVisible: currentVisible);
}
