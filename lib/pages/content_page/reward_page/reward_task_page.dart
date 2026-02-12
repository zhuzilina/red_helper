import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/points_state.dart';
import '../../../repository/api/api.dart';
import '../../../repository/api/api_kits.dart';
import 'widget/task/app_bar_content.dart';
import 'widget/task/sign_section.dart';
import 'widget/task/task_item.dart';
import 'widget/task/sticky_header_delegate.dart';
import 'package:red_helper/repository/models/model.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  // 处理登录状态
  bool _isLogin = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String token = '';
  final ApiService _apiService = ApiService('');
  List<DailyTask> _tasks = [];
  final List<DateTime> _signDates = [
    DateTime.now().subtract(const Duration(days: 4)),
    DateTime.now().subtract(const Duration(days: 3)),
    DateTime.now().subtract(const Duration(days: 2)),
    DateTime.now().subtract(const Duration(days: 1)),
  ];
  bool _hasSigned = false;
  int _continuousDays = 4;
  @override
  void initState() {
    super.initState();
    _refreshData(); // 获取token
    _loadTask();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pointsState = Provider.of<PointsState>(context, listen: false);
      pointsState.fetchPoints();
    });
  }

  Future<void> _refreshData() async {
    try {
      token = await loadToken();
      if (mounted) {
        setState(() => _isLogin = token.isNotEmpty);
      }
      _apiService.token = token;
      if (_isLogin) await _loadTask();
    } catch (e) {
      if (mounted) {}
    }
  }

  Future<void> _loadTask() async {
    if (!_isLogin) return;
    setState(() => _isLoading = true);
    try {
      final tasks = await _apiService.getDailyTask();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsState = Provider.of<PointsState>(context);
    return Scaffold(
      body: Stack(
        children: [
          AppBarContent(currentPoints: pointsState.currentPoints),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                flexibleSpace: const SizedBox(),
                backgroundColor: Colors.transparent,
                title: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '规则',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'blockLetter',
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
              ),
              SliverToBoxAdapter(
                child: SignSection(
                  hasSigned: _hasSigned,
                  signDates: _signDates,
                  continuousDays: _continuousDays,
                  onSign: _handleSign,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyHeaderDelegate(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      '每日任务',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = _tasks[index];
                  return TaskItem(
                    task: task,
                    onComplete: () async {
                      // 调用API并等待结果
                      bool isOK = await _apiService.updateTask();
                      if (isOK) {
                        // 使用setState触发重建
                        setState(() {
                          _tasks[index].completed = true;
                        });
                      }
                    },
                  );
                }, childCount: _tasks.length),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSign(DateTime date) {
    if (!_hasSigned) {
      setState(() {
        _hasSigned = true;
        _continuousDays++;
        _signDates.add(date);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('签到成功！+10积分')));
    }
  }
}
