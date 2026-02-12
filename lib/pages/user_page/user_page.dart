import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_helper/route/routes.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:red_helper/pages/content_page/web_view/web_view.dart';

import '../../providers/points_state.dart';
import 'widget/profile_card.dart';
import 'widget/achievement_card.dart';
import 'widget/points_card.dart';
import 'widget/reward_card.dart';
import 'widget/setting_item.dart';
import 'widget/list_header.dart';
import 'widget/logout_button.dart';
import 'widget/login_setting_item.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with RouteAware {
  bool _isLoggedIn = false;
  // 网络连接状态
  bool _hasNetworkConnection = true;
  String _networkErrorMessage = '';

  Map<String, dynamic> userInfo = {
    'background': 'https://picsum.photos/400/200?random=1',
    'avatar': 'http://121.36.87.174:3000/api/image/687877d06442262e7ef49df8',
    'nickname': '旅行达人小美',
    'gender': Icons.female,
    'birthday': '1995-08-20',
    'bio': '世界那么大，我想去看看！🚀',
    'points': 2560,
  };

  final List<Map<String, dynamic>> achievements = [
    {'name': '初出茅庐', 'icon': Icons.flag, 'unlocked': true},
    {'name': '百公里挑战', 'icon': Icons.directions_walk, 'unlocked': true},
    {'name': '摄影大师', 'icon': Icons.camera_alt, 'unlocked': false},
    {'name': '美食达人', 'icon': Icons.restaurant, 'unlocked': false},
  ];

  final List<Map<String, dynamic>> rewards = [
    {
      'name': '马克杯',
      'points': 500,
      'image':
          'https://tse1-mm.cn.bing.net/th/id/OIP-C.XCDKAyHauOG6yBZWxmc3PAHaGR?w=249&h=211&c=7&r=0&o=5&dpr=1.2&pid=1.7%27,',
    },
    {
      'name': '红星照耀中国',
      'points': 1500,
      'image':
          'https://bkimg.cdn.bcebos.com/pic/b999a9014c086e061d95d6c928506cf40ad163d95da2?x-bce-process=image/format,f_auto/quality,Q_70/resize,m_lfit,limit_1,w_536',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkNetworkConnection();
      await _checkLoginStatus(); // 初始检查
      if (_isLoggedIn && _hasNetworkConnection) {
        final pointsState = Provider.of<PointsState>(context, listen: false);
        pointsState.fetchPoints();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ModalRoute? route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _checkLoginStatus(); // 返回页面时重新检查
  }

  // 检查网络连接状态
  Future<void> _checkNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      if (!mounted) return; // 提前检查mounted状态

      setState(() {
        _hasNetworkConnection = hasConnection;
        if (!hasConnection) {
          _networkErrorMessage = '网络连接不可用，请检查网络设置';
        } else {
          _networkErrorMessage = '';
        }
      });
    } catch (e) {
      // 如果无法检查网络状态，假设有网络连接
      if (mounted) {
        setState(() => _hasNetworkConnection = true);
      }
    }
  }

  // 优化登录状态检查：添加异常捕获，确保状态更新
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      // 严格判断token存在且非空
      final isLoggedIn = token != null && token.trim().isNotEmpty;
      if (mounted) {
        // 确保页面未销毁再更新状态
        setState(() => _isLoggedIn = isLoggedIn);
      }
    } catch (e) {
      // 异常情况下默认未登录
      if (mounted) {
        setState(() => _isLoggedIn = false);
      }
    }
  }

  // 优化登录处理：无论结果如何都重新检查状态
  Future<void> _login() async {
    // 导航到登录页并等待结果
    await Navigator.pushNamed(context, RoutePath.login);
    // 登录页返回后强制重新检查状态（无论成功失败）
    await _checkLoginStatus();
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token'); // 移除token
    } catch (e) {
      // 忽略移除失败的情况
    }
    if (mounted) {
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    userInfo['points'] = Provider.of<PointsState>(context).currentPoints;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 网络错误提示
          if (!_hasNetworkConnection)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _networkErrorMessage,
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _checkNetworkConnection();
                        if (_hasNetworkConnection && _isLoggedIn) {
                          final pointsState = Provider.of<PointsState>(
                            context,
                            listen: false,
                          );
                          pointsState.fetchPoints();
                        }
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: ProfileCard(
              isLoggedIn: _isLoggedIn,
              userInfo: userInfo,
              onLogin: _login,
            ),
          ),

          if (_isLoggedIn) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: achievements.length,
                    padding: const EdgeInsets.only(left: 16),
                    itemBuilder: (context, index) =>
                        AchievementCard(achievement: achievements[index]),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.only(bottom: 12),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: rewards.length + 1,
                    padding: const EdgeInsets.only(left: 16),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return PointsCard(points: userInfo['points']);
                      }
                      return RewardCard(reward: rewards[index - 1]);
                    },
                  ),
                ),
              ),
            ),
          ],

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ListHeader(title: '账户设置'),
                SettingItem(icon: Icons.settings, title: '账号设置'),
                SettingItem(icon: Icons.security, title: '隐私设置'),
                _isLoggedIn
                    ? LogoutButton(onLogout: _logout)
                    : LoginSettingItem(onLogin: _login),
                ListHeader(title: '应用设置'),
                SettingItem(icon: Icons.feedback, title: '意见反馈'),
                SettingItem(icon: Icons.update, title: '检查更新'),
                SettingItem(icon: Icons.help_outline, title: '用户协议'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return _isLoggedIn
        ? Stack(
            children: [
              Image.network(
                userInfo['background']! as String,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          userInfo['avatar']! as String,
                        ),
                        radius: 40,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userInfo['nickname']! as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Text('🎂 ${userInfo['birthday']}'),
                      const SizedBox(height: 8),
                      Text(
                        userInfo['bio']! as String,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('请登录查看个人信息'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('立即登录'),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildLogoutButton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('退出登录'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLogoutDialog(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildLoginSettingItem() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(
          Icons.login,
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
        title: const Text('登录账户'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _login,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出登录？'),
        content: const Text('退出后需要重新登录才能查看个人信息'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _logout();
              Navigator.pop(context);
            },
            child: Text(
              '确认退出',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // 以下保持原有组件不变...
  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                achievement['icon'] as IconData,
                color: achievement['unlocked']
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                achievement['name'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: achievement['unlocked']
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  fontSize: 12,
                ),
              ),
              if (!achievement['unlocked'])
                const Icon(Icons.lock_outline, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '我的积分',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                userInfo['points'].toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('兑换奖品'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Image.network(
              reward['image']! as String,
              height: 80,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${reward['points']}积分'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
