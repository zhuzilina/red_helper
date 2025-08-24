import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'generate.dart';
import '../../../repository/models/topic.dart';
import '../../../utils/global_oauth_manager.dart';
import '../../../repository/api/question_answer_api.dart';
import '../../../providers/question_answer_provider.dart';

class SuperPage extends StatefulWidget {
  final String? topicName;

  const SuperPage({super.key, this.topicName});

  @override
  State<SuperPage> createState() => _SuperPageState();
}

class _SuperPageState extends State<SuperPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 数据状态
  Topic? _topic;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;
  bool _isDataLoading = false;
  bool _isTokenRefreshing = false;

  // 主题名称
  late String _currentTopicName;

  // OAuth服务实例
  GlobalOAuthManager? _oAuthManager;

  @override
  void initState() {
    super.initState();
    print("🚀 SuperPage initState 开始");

    try {
      _currentTopicName = widget.topicName ?? "邓小平";
      print("✅ 主题名称设置: $_currentTopicName");

      // 初始化OAuth服务
      _oAuthManager = GlobalOAuthManager();

      // 设置页面控制器监听器
      _pageController.addListener(() {
        if (!_isDisposed && mounted) {
          final page = _pageController.page;
          if (page != null) {
            _safeSetState(() {
              _currentPage = page.round();
            });
          }
        }
      });

      // 延迟加载数据
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTopicData();
      });
    } catch (e) {
      print("❌ initState异常: $e");
      _safeSetState(() {
        _errorMessage = '初始化失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    super.dispose();
  }

  // 安全的状态更新方法
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // 检查token状态
  Future<bool> _checkTokenStatus() async {
    if (_oAuthManager == null) {
      print("❌ OAuth服务未初始化");
      return false;
    }

    try {
      await _oAuthManager!.initialize();
      final accessToken = await _oAuthManager!.getAccessToken();
      return accessToken.isNotEmpty;
    } catch (e) {
      print("❌ 检查token状态失败: $e");
      return false;
    }
  }

  // 刷新token
  Future<bool> _refreshToken() async {
    if (_oAuthManager == null) {
      print("❌ OAuth服务未初始化");
      return false;
    }

    try {
      _safeSetState(() {
        _isTokenRefreshing = true;
      });

      await _oAuthManager!.initialize();
      final accessToken = await _oAuthManager!.getAccessToken();

      _safeSetState(() {
        _isTokenRefreshing = false;
      });

      return accessToken.isNotEmpty;
    } catch (e) {
      print("❌ 刷新token失败: $e");
      _safeSetState(() {
        _isTokenRefreshing = false;
      });
      return false;
    }
  }

  // 加载主题数据
  Future<void> _loadTopicData() async {
    if (_isDataLoading || _isTokenRefreshing) {
      print("⚠️ 正在加载中，跳过重复请求");
      return;
    }

    _safeSetState(() {
      _isDataLoading = true;
      _errorMessage = null;
    });

    try {
      // 检查token状态
      final tokenValid = await _checkTokenStatus();
      if (!tokenValid) {
        print("🔄 Token无效，尝试刷新");
        final refreshSuccess = await _refreshToken();
        if (!refreshSuccess) {
          _safeSetState(() {
            _errorMessage = '认证失败，请重新登录';
            _isDataLoading = false;
            _isLoading = false;
          });
          return;
        }
      }

      // 生成主题数据
      final topic = await _generateTopicDataAsync();
      if (topic == null) {
        _safeSetState(() {
          _errorMessage = '获取的数据不完整，请重试';
          _isDataLoading = false;
          _isLoading = false;
        });
        return;
      }

      _safeSetState(() {
        _topic = topic;
        _isDataLoading = false;
        _isLoading = false;
      });

      // 延迟预加载所有问题的解答，确保OAuth服务已准备就绪
      Future.delayed(const Duration(seconds: 2), () {
        _preloadAllAnswers();
      });

      print("✅ 主题数据加载成功");
    } catch (e) {
      print("❌ 加载主题数据失败: $e");
      _safeSetState(() {
        _errorMessage = '无法获取主题数据，请检查网络连接';
        _isDataLoading = false;
        _isLoading = false;
      });
    }
  }

  // 异步生成主题数据
  Future<Topic?> _generateTopicDataAsync() async {
    try {
      return await extractAndParseOutput(_currentTopicName);
    } catch (e) {
      print("❌ 生成主题数据失败: $e");
      return null;
    }
  }

  // 获取问题解答（使用Provider）
  Future<void> _getQuestionAnswer(int questionIndex) async {
    if (_topic == null) {
      print("❌ 主题数据未初始化");
      return;
    }

    final questionAnswerProvider = Provider.of<QuestionAnswerProvider>(
      context,
      listen: false,
    );
    final question = _topic!.questions[questionIndex];

    // 使用Provider获取解答
    await questionAnswerProvider.getAnswer(question);
  }

  // 预加载所有问题的解答
  void _preloadAllAnswers() {
    if (_topic == null) {
      print("❌ 主题数据未初始化，无法预加载");
      return;
    }

    try {
      final questionAnswerProvider = Provider.of<QuestionAnswerProvider>(
        context,
        listen: false,
      );

      print("🔄 开始预加载 ${_topic!.questions.length} 个问题的解答");
      print("📋 问题列表:");
      for (int i = 0; i < _topic!.questions.length; i++) {
        final question = _topic!.questions[i];
        print(
          "  ${i + 1}. ${question.substring(0, question.length > 40 ? 40 : question.length)}...",
        );
      }

      questionAnswerProvider.preloadAnswers(_topic!.questions);

      // 延迟检查缓存状态
      Future.delayed(const Duration(seconds: 5), () {
        print("🔍 预加载5秒后的缓存状态:");
        questionAnswerProvider.debugCache();
      });
    } catch (e) {
      print("❌ 预加载问题解答失败: $e");
    }
  }

  // 跳转到指定页面
  void _jumpToPage(int index) {
    if (_topic != null && index >= 0 && index < _topic!.questions.length + 1) {
      try {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        Navigator.of(context).maybePop();
      } catch (e) {
        print("❌ 跳转页面异常: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_topic == null) {
      return _buildErrorView();
    }

    return _buildMainContent();
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.purple],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _isTokenRefreshing ? '正在刷新认证信息...' : '正在加载主题数据...',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red, Colors.orange],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? '加载失败',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: (_isDataLoading || _isTokenRefreshing)
                    ? null
                    : _loadTopicData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical, // 垂直滚动，类似抖音风格
          itemCount: _topic!.questions.length + 1,
          onPageChanged: (index) {
            _safeSetState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildOverviewPage();
            } else {
              final questionIndex = index - 1;
              final question = _topic!.questions[questionIndex];

              // 自动获取问题解答
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _getQuestionAnswer(questionIndex);
              });

              return _buildQuestionPage(question, questionIndex, index);
            }
          },
        ),

        // 右侧页面指示器（垂直滚动）
        if (_topic!.questions.length > 0)
          Positioned(
            top: 0,
            bottom: 0,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_currentPage + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 20,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    Text(
                      '${_topic!.questions.length + 1}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 构建总览页面
  Widget _buildOverviewPage() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.purple],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // 主题名称
                  Text(
                    _topic!.topic,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 主题介绍（纯文本，无卡片/边框）
                  Text(
                    _topic!.detail,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 问题概览标题
                  Text(
                    '我们将从以下问题进一步了解「${_topic!.topic}」',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 问题概览（纯文本列表，无卡片/边框）
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (
                        int index = 0;
                        index < _topic!.questions.length;
                        index++
                      )
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _topic!.questions.length - 1
                                ? 10
                                : 0,
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${index + 1}. ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: _topic!.questions[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 底部提示（纯文本）
                  Row(
                    children: [
                      Icon(
                        Icons.swipe_up,
                        size: 18,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '向上滑动查看详细问题',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 右侧交互按钮
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              _buildInteractionButton(icon: Icons.favorite, count: 128),
              const SizedBox(height: 25),
              _buildInteractionButton(icon: Icons.comment, count: 32),
              const SizedBox(height: 25),
              _buildInteractionButton(icon: Icons.share, count: 16),
              const SizedBox(height: 25),
              // 调试按钮 - 手动刷新缓存
              GestureDetector(
                onTap: () {
                  final questionAnswerProvider =
                      Provider.of<QuestionAnswerProvider>(
                        context,
                        listen: false,
                      );
                  questionAnswerProvider.debugCache();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('缓存状态已打印到控制台')));
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建问题页面（垂直滚动风格）
  Widget _buildQuestionPage(String question, int questionIndex, int pageIndex) {
    return Consumer<QuestionAnswerProvider>(
      builder: (context, questionAnswerProvider, child) {
        final isLoading = questionAnswerProvider.isLoading(question);
        final answer = questionAnswerProvider.getCachedAnswer(question);

        // 调试信息
        if (pageIndex == 1) {
          // 只在第一个问题页面打印调试信息
          print("🔍 问题页面调试 - 问题$pageIndex:");
          print(
            "  问题内容: ${question.substring(0, question.length > 20 ? 20 : question.length)}...",
          );
          print("  是否加载中: $isLoading");
          print("  是否有缓存: ${answer != null}");
          if (answer != null) {
            print("  缓存内容长度: ${answer.answer.length}");
          }
          questionAnswerProvider.debugCache();
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.primaries[pageIndex % Colors.primaries.length].shade700,
                Colors.primaries[pageIndex % Colors.primaries.length].shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部区域
                  Row(
                    children: [
                      // 问题标题
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.quiz,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '问题 ${pageIndex}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // 右侧交互按钮
                      _buildInteractionButton(
                        icon: Icons.favorite,
                        count: pageIndex * 50,
                      ),
                      const SizedBox(width: 15),
                      _buildInteractionButton(
                        icon: Icons.comment,
                        count: pageIndex * 10,
                      ),
                      const SizedBox(width: 15),
                      _buildInteractionButton(icon: Icons.share, count: 0),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 问题内容
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 解答内容卡片
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (answer != null && answer.hasContent) {
                          _showFullAnswerDialog(question, answer, pageIndex);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 解答标题
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'AI解答',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const Spacer(),
                                if (answer != null && answer.hasContent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '点击查看',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // 解答内容
                            if (isLoading)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'AI正在思考中...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (answer != null && answer.hasContent)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 解答文本（前150字）
                                    Expanded(
                                      child: Text(
                                        _getAnswerPreview(answer.answer),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),

                                    // 查看更多提示
                                    if (answer.answer.length > 150)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.expand_more,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '展开完整解答',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            else
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.white.withOpacity(0.4),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '等待AI解答...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建交互按钮
  Widget _buildInteractionButton({required IconData icon, required int count}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          if (count > 0)
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
        ],
      ),
    );
  }

  // 构建浮动操作按钮
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: (_isDataLoading || _isTokenRefreshing)
          ? Colors.grey
          : Colors.blue,
      onPressed: (_isDataLoading || _isTokenRefreshing) ? null : _loadTopicData,
      tooltip: (_isDataLoading || _isTokenRefreshing) ? '加载中...' : '刷新',
      child: (_isDataLoading || _isTokenRefreshing)
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.refresh),
    );
  }

  // 构建抽屉
  Widget _buildDrawer() {
    if (_topic == null) {
      return Drawer(
        backgroundColor: Colors.black.withOpacity(0.9),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              const Text(
                '暂无数据',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '主题: $_currentTopicName',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_isDataLoading || _isTokenRefreshing)
                    ? null
                    : _loadTopicData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: (_isDataLoading || _isTokenRefreshing)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // 抽屉头部
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.topic,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _topic!.topic,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '页面目录',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 页面列表
          Expanded(
            child: ListView.separated(
              itemCount: _topic!.questions.length + 1,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey[700], height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: Icon(
                      Icons.dashboard,
                      color: Colors.primaries[index % Colors.primaries.length],
                    ),
                    title: const Text(
                      '主题总览',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600]!,
                    ),
                    onTap: () => _jumpToPage(index),
                  );
                } else {
                  final questionIndex = index - 1;
                  return ListTile(
                    leading: Icon(
                      Icons.quiz,
                      color: Colors
                          .primaries[questionIndex % Colors.primaries.length],
                    ),
                    title: Text(
                      '问题 ${index}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _topic!.questions[questionIndex],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600]!,
                    ),
                    onTap: () => _jumpToPage(index),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 获取解答预览（前150字）
  String _getAnswerPreview(String answer) {
    if (answer.length <= 150) {
      return answer;
    }
    return '${answer.substring(0, 150)}...';
  }

  // 显示完整解答弹窗
  void _showFullAnswerDialog(
    String question,
    QuestionAnswerResponse answer,
    int pageIndex,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors
                      .primaries[pageIndex % Colors.primaries.length]
                      .shade700,
                  Colors
                      .primaries[pageIndex % Colors.primaries.length]
                      .shade900,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // 弹窗头部
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '问题 ${pageIndex} 完整解答',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 弹窗内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 问题内容
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            question,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 完整解答文本
                        if (answer.answer.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '完整解答',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  answer.answer,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 图片
                        if (answer.images.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '相关图片',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...answer.images.map(
                                  (imageUrl) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: double.infinity,
                                                height: 200,
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                  size: 48,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 问题建议
                        if (answer.suggestions.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.question_answer,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '相关问题',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...answer.suggestions.map(
                                  (suggestion) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      suggestion,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
