import 'package:flutter/material.dart';

class SuperPage extends StatefulWidget {
  const SuperPage({super.key});

  @override
  State<SuperPage> createState() => _SuperPageState();
}

class _SuperPageState extends State<SuperPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 模拟视频数据
  final List<Map<String, dynamic>> _videos = List.generate(
    10,
    (index) => {
      'id': index,
      'color': Colors.primaries[index % Colors.primaries.length].shade700,
      'user': '用户${index + 1}',
      'description': '这是第${index + 1}个视频描述 #标签${index}',
      'likes': (index + 1) * 100,
      'comments': (index + 1) * 20,
    },
  );

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 跳转到指定页面
  void _jumpToPage(int index) {
    if (index >= 0 && index < _videos.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      // 关闭抽屉
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              final video = _videos[index];
              return Stack(
                children: [
                  // 视频卡片背景
                  Container(
                    color: video['color'],
                    child: Center(
                      child: Text(
                        '视频内容 ${index + 1}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        _buildInteractionButton(
                          icon: Icons.favorite,
                          count: video['likes'],
                        ),
                        const SizedBox(height: 25),
                        _buildInteractionButton(
                          icon: Icons.comment,
                          count: video['comments'],
                        ),
                        const SizedBox(height: 25),
                        _buildInteractionButton(icon: Icons.share, count: 0),
                      ],
                    ),
                  ),

                  // 底部用户信息
                  Positioned(
                    left: 16,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['user'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // 顶部指示器
          if (_videos.length > 1)
            Positioned(
              top: 40,
              right: 20,
              child: Text(
                '${_currentPage + 1}/${_videos.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),

          // 左上角抽屉入口按钮
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black54,
              child: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
        ],
      ),
    );
  }

  // 抽屉组件 - 现在显示视频目录
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // 抽屉头部（保留用户区域）
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
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 26, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '用户昵称',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '@用户名',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('关注', '1.2K'),
                    _buildStatItem('粉丝', '8.7K'),
                    _buildStatItem('获赞', '42.5K'),
                  ],
                ),
              ],
            ),
          ),

          // 标题：视频目录
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '视频目录',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '共${_videos.length}个视频',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // 视频目录列表
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _videos.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey[800],
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final video = _videos[index];
                return ListTile(
                  minVerticalPadding: 15,
                  tileColor: _currentPage == index
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.transparent,
                  leading: Container(
                    width: 60,
                    height: 60,
                    color: video['color'],
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    video['user'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    video['description'].length > 25
                        ? '${video['description'].substring(0, 25)}...'
                        : video['description'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCount(video['likes']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  onTap: () => _jumpToPage(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 用户统计信息项
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildInteractionButton({required IconData icon, required int count}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(height: 4),
        if (count > 0)
          Text(
            _formatCount(count),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 10000).toStringAsFixed(1)}W';
  }
}
