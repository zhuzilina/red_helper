import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_helper/pages/content_page/question/question.dart';

class PKPage extends StatefulWidget {
  const PKPage({super.key});

  @override
  _PKState createState() => _PKState();
}

class _PKState extends State<PKPage> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  bool _matched = false;
  bool _isLoading = false;
  Timer? _matchingTimer;
  late AnimationController _titleController;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化标题动画控制器
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _titleAnimation = Tween(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );

    // 开始匹配计时器
    _startMatching();
  }

  void _startMatching() {
    _matchingTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      setState(() {
        _progress += 0.2;
        if (_progress >= 1.0) {
          timer.cancel();
          _matchSuccess();
        }
      });
    });
  }

  void _matchSuccess() {
    setState(() {
      _matched = true;
      _titleController.stop();
    });
  }

  void _startPK() {
    setState(() {
      _isLoading = true;
    });

    // 模拟加载过程
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DailyQuizPage(title: '123')),
      );
    });
  }

  Future<void> _cancelMatching() async {
    if (_isLoading) return;

    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('取消匹配'),
                content: const Text('确定要取消匹配吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确定'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm && mounted) {
      _matchingTimer?.cancel();
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _matchingTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 禁用屏幕旋转
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('答题PK')),
      body: Container(
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  AnimatedBuilder(
                    animation: _titleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _matched ? 1.1 : _titleAnimation.value,
                        child: Text(
                          _matched ? "匹配成功！" : "正在寻找对手🔥",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Color.fromRGBO(0, 0, 0, 0.2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // 头像区域
                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 用户头像
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: const CircleAvatar(
                              radius: 45,
                              backgroundImage: NetworkImage(
                                'https://picsum.photos/200/150?random=1',
                              ),
                            ),
                          ),
                        ),

                        // 加载动画
                        if (!_matched) ...[
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],

                        // 对手头像
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 500),
                          right:
                              _matched
                                  ? 0
                                  : -MediaQuery.of(context).size.width / 4,
                          top: 0,
                          bottom: 0,
                          child: Transform.scale(
                            scale: _matched ? 1.0 : 0.5,
                            child: Opacity(
                              opacity: _matched ? 1.0 : 0.0,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white.withOpacity(0.8),
                                child: const CircleAvatar(
                                  radius: 45,
                                  backgroundImage: NetworkImage(
                                    'https://picsum.photos/200/150?random=2',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 进度条
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width:
                            MediaQuery.of(context).size.width * 0.6 * _progress,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.surface,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 匹配成功提示
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _matched ? 1.0 : 0.0,
                    child: Transform.translate(
                      offset: Offset(0, _matched ? 0 : 20),
                      child: const Text(
                        '   匹配成功！',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 加载状态或按钮
                  if (_isLoading) ...[
                    const Column(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(strokeWidth: 4),
                        ),
                        SizedBox(height: 16),
                        Text('加载中...', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ] else ...[
                    InkWell(
                      onTap: _matched ? _startPK : _cancelMatching,
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 48,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Text(
                          _matched ? '开始PK' : '取消匹配',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
