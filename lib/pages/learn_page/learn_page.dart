import 'package:flutter/material.dart';
import 'package:red_helper/coze_page.dart';
import 'package:red_helper/repository/api/api.dart';
import 'package:red_helper/repository/models/model.dart';
import 'package:red_helper/repository/api/api_kits.dart';
import 'package:red_helper/pages/content_page/web_view/web_view_page.dart';

import '../content_page/question/pk.dart';
import '../content_page/question/question.dart';
import 'widget/quiz/quiz_card.dart';
import 'widget/book_grid/book_grid_item.dart';
import 'widget/book_grid/more_button.dart';
import 'widget/information/information_card.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  // 处理登录状态
  bool _isLogin = false;
  String token = '';
  final ApiService _apiService = ApiService('');
  // 连接数据
  List<Book> _bookWinnow = [];
  List<Book> _books = [];
  bool _isLoading = false;
  String _errorMessage = '';
  // 模拟数据
  final List<String> books = ['毛泽东选集', '红星照耀中国', '红岩', '可爱的中国'];
  final List<Map<String, String>> testimonials = [
    {'user': '用户1', 'comment': '这个学习平台太棒了！'},
    {'user': '用户2', 'comment': '每日答题帮助我巩固知识'},
    {'user': '用户3', 'comment': '推荐给所有想学习的朋友'},
  ];
  final List<Map<String, String>> _newsItems = [
    {
      'cover': 'https://picsum.photos/200/150?random=1',
      'title': '人工智能在教育领域的应用趋势',
      'date': '2024-03-15',
      'category': '科技',
    },
    {
      'cover': 'https://picsum.photos/200/150?random=2',
      'title': '经典文学阅读推荐书单',
      'date': '2024-03-14',
      'category': '人文',
    },
    {
      'cover': 'https://picsum.photos/200/150?random=3',
      'title': '最新教育政策解读',
      'date': '2024-03-13',
      'category': '教育',
    },
  ];
  int _selectedNewsCategory = 0;
  @override
  void initState() {
    super.initState();
    _refreshData(); // 获取token
    _loadBookWinnow();
  }

  Future<void> _refreshData() async {
    try {
      token = await loadToken();
      if (mounted) {
        setState(() => _isLogin = token.isNotEmpty);
      }
      _apiService.token = token;
      if (_isLogin) await _loadBookWinnow();
      if (_isLogin) await _loadBook();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '加载 Token 失败');
      }
    }
  }

  Future<void> _loadBookWinnow() async {
    if (!_isLogin) return;
    setState(() => _isLoading = true);
    try {
      final winnow = await _apiService.getBookWinnow();
      if (mounted) {
        setState(() {
          _bookWinnow = winnow;
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

  Future<void> _loadBook() async {
    if (!_isLogin) return;
    setState(() => _isLoading = true);
    try {
      final book = await _apiService.getBook();
      if (mounted) {
        setState(() {
          _books = book;
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
    return Scaffold(
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 280,
            right: 2,
            child: DigitaPsersonFloatViewHome(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 答题卡片
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: QuizGrid(
                  onQuizPressed: (type) => _handleQuizStart(type),
                ),
              ),
            ),
          ),

          // 书籍网格
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _books.length) {
                    return BookGridItem(
                      title: _books[index].title,
                      imageUrl: _books[index].coverUrl, // 假设 Book 类包含 cover 字段
                    );
                  }
                  return const MoreButton();
                },
                childCount: _books.length + 1, // 动态计算子项数量
              ),
            ),
          ),
          // 信息卡片
          SliverToBoxAdapter(
            child: InformationCard(
              newsItems: _newsItems,
              selectedCategoryIndex: _selectedNewsCategory,
              onCategoryChanged: (index) {
                setState(() => _selectedNewsCategory = index);
                // 这里可以添加分类过滤逻辑
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuizStart(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => type == 'daily'
            ? DailyQuizPage(title: null)
            : type == 'pk'
            ? PKPage()
            : ContentPage(
                assetPath:
                    'assets/html/pages/${type == 'daily'
                        ? 'daily'
                        : type == 'pk'
                        ? 'pk'
                        : 'leaderboard'}.html',
                title: type == 'daily'
                    ? '每日一答'
                    : type == 'pk'
                    ? '答题PK'
                    : '排行榜',
              ),
      ),
    );
  }
}

class DigitaPsersonFloatViewHome extends StatelessWidget {
  const DigitaPsersonFloatViewHome({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight * 0.9,
              child: ClipRRect(child: CozePage(callMsg: '')),
            ),
          );
        },
      ),
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Image.asset('assets/images/digital_person.png'),
            Card(
              margin: EdgeInsets.fromLTRB(2, 0, 2, 2),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                child: Text('你好呀，我是小红同学，有红色文化相关的问题都可以来问我哦🙂'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiInputWidget extends StatefulWidget {
  const AiInputWidget({super.key});
  @override
  State<StatefulWidget> createState() {
    return _AiInputWidgetState();
  }
}

class _AiInputWidgetState extends State<AiInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '小红同学',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 60,
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                ),
                hint: Text(
                  '向小红同学提问',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: EdgeInsets.only(left: 30), child: Text('建议:')),
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 7,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CozePage(callMsg: '讲解一下遵义会议'),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 120,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 2, 2, 2),
                          child: Text(
                            '讲解一下遵义会议',
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 2, 2, 2),
                        child: Text(
                          '二十大报告的主要内容总结',
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 2, 2, 2),
                        child: Text(
                          '介绍一下江姐',
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(flex: 1, child: SizedBox(height: 1)),
            ],
          ),
        ],
      ),
    );
  }
}
