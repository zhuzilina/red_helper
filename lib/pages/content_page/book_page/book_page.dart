import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

// 数据模型定义
class BigChapter {
  final String bigChapterNumber;
  final String bigChapterTitle;
  final List<SmallChapter> smallChapters;

  BigChapter({
    required this.bigChapterNumber,
    required this.bigChapterTitle,
    required this.smallChapters,
  });

  factory BigChapter.fromJson(Map<String, dynamic> json) {
    var smallChaptersList = json['small_chapters'] as List;
    List<SmallChapter> smallChaptersItems = smallChaptersList
        .map((i) => SmallChapter.fromJson(i))
        .toList();

    return BigChapter(
      bigChapterNumber: json['big_chapter_number'],
      bigChapterTitle: json['big_chapter_title'],
      smallChapters: smallChaptersItems,
    );
  }
}

class SmallChapter {
  final String smallChapterNumber;
  final String smallChapterTitle;
  final String content;

  SmallChapter({
    required this.smallChapterNumber,
    required this.smallChapterTitle,
    required this.content,
  });

  factory SmallChapter.fromJson(Map<String, dynamic> json) {
    return SmallChapter(
      smallChapterNumber: json['small_chapter_number'],
      smallChapterTitle: json['small_chapter_title'],
      content: json['content'],
    );
  }
}

// 阅读页面（主页面）
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  List<BigChapter> bigChapters = [];
  bool isLoading = true;
  // 当前阅读位置
  BigChapter? currentBigChapter;
  SmallChapter? currentSmallChapter;

  @override
  void initState() {
    super.initState();
    loadJsonData();
  }

  Future<void> loadJsonData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/books/book01_md.json',
      );
      final data = json.decode(response);

      setState(() {
        bigChapters = (data as List)
            .map((i) => BigChapter.fromJson(i))
            .toList();
        // 默认显示第一个章节内容
        if (bigChapters.isNotEmpty &&
            bigChapters.first.smallChapters.isNotEmpty) {
          currentBigChapter = bigChapters.first;
          currentSmallChapter = bigChapters.first.smallChapters.first;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载数据失败: $e')));
      }
    }
  }

  // 切换章节
  void switchChapter(BigChapter bigChapter, SmallChapter smallChapter) {
    setState(() {
      currentBigChapter = bigChapter;
      currentSmallChapter = smallChapter;
    });
    // 关闭目录
    Navigator.pop(context);
  }

  // 打开目录
  void openChapterList() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // 半透明
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChapterListScreen(
              bigChapters: bigChapters,
              currentBigChapter: currentBigChapter,
              currentSmallChapter: currentSmallChapter,
              onChapterSelected: switchChapter,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // 悬浮按钮 - 目录入口
      floatingActionButton: FloatingActionButton(
        onPressed: openChapterList,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.bookmarks),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : currentSmallChapter != null && currentBigChapter != null
          ? ContentDisplay(
              bigChapter: currentBigChapter!,
              smallChapter: currentSmallChapter!,
              context: context,
            )
          : const Center(child: Text('没有找到内容')),
    );
  }
}

// 目录页面
class ChapterListScreen extends StatelessWidget {
  final List<BigChapter> bigChapters;
  final BigChapter? currentBigChapter;
  final SmallChapter? currentSmallChapter;
  final Function(BigChapter, SmallChapter) onChapterSelected;

  const ChapterListScreen({
    super.key,
    required this.bigChapters,
    required this.currentBigChapter,
    required this.currentSmallChapter,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black54, // 背景半透明
      body: SafeArea(
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '章节列表',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 章节列表
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _calculateItemCount(),
                  itemBuilder: (context, index) =>
                      _buildChapterItem(context, index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 计算列表总项数（大章节标题 + 小章节数量）
  int _calculateItemCount() {
    int count = 0;
    for (var bigChapter in bigChapters) {
      count += 1 + bigChapter.smallChapters.length;
    }
    return count;
  }

  // 构建列表项
  Widget _buildChapterItem(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    int currentIndex = 0;
    for (var bigChapter in bigChapters) {
      // 大章节标题
      if (currentIndex == index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: colorScheme.primaryContainer,
          child: Text(
            '${bigChapter.bigChapterNumber}章 ${bigChapter.bigChapterTitle}',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
      currentIndex++;

      // 小章节列表
      for (var smallChapter in bigChapter.smallChapters) {
        if (currentIndex == index) {
          // 判断是否为当前章节
          bool isCurrent =
              currentBigChapter == bigChapter &&
              currentSmallChapter == smallChapter;

          return ListTile(
            title: Text(
              '第${smallChapter.smallChapterNumber}节 ${smallChapter.smallChapterTitle}',
              style: TextStyle(
                color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            leading: isCurrent
                ? Icon(Icons.check, color: colorScheme.primary)
                : null,
            onTap: () => onChapterSelected(bigChapter, smallChapter),
          );
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }
}

// 内容展示组件
class ContentDisplay extends StatelessWidget {
  final BigChapter bigChapter;
  final SmallChapter smallChapter;
  final BuildContext context;

  const ContentDisplay({
    super.key,
    required this.bigChapter,
    required this.smallChapter,
    required this.context,
  });

  // 解析文本内容为不同类型的组件
  List<Widget> _parseContent(String content) {
    final widgets = <Widget>[];
    final lines = content.split('\n');
    final buffer = StringBuffer();
    bool inQuote = false;

    for (var line in lines) {
      // 处理分割线
      if (line.trim() == '---') {
        // 如果缓冲区有内容，先添加文本
        if (buffer.isNotEmpty) {
          widgets.add(_buildTextWidget(buffer.toString()));
          buffer.clear();
        }
        // 添加分割线
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(thickness: 2, height: 2),
          ),
        );
        continue;
      }

      // 处理引用开始
      if (line.startsWith('>') && !inQuote) {
        // 如果缓冲区有内容，先添加文本
        if (buffer.isNotEmpty) {
          widgets.add(_buildTextWidget(buffer.toString()));
          buffer.clear();
        }
        inQuote = true;
        // 添加引用内容（去除>符号和可能的空格）
        buffer.write(line.substring(1).trimLeft() + '\n');
        continue;
      }

      // 处理引用结束
      if (!line.startsWith('>') && inQuote) {
        inQuote = false;
        // 添加引用卡片
        widgets.add(_buildQuoteWidget(buffer.toString().trim()));
        buffer.clear();
      }

      // 添加内容到缓冲区
      if (inQuote) {
        // 引用内容处理
        buffer.write(
          line.startsWith('>')
              ? line.substring(1).trimLeft() + '\n'
              : line + '\n',
        );
      } else {
        // 普通文本处理
        buffer.write(line + '\n');
      }
    }

    // 处理剩余内容
    if (buffer.isNotEmpty) {
      if (inQuote) {
        widgets.add(_buildQuoteWidget(buffer.toString().trim()));
      } else {
        widgets.add(_buildTextWidget(buffer.toString().trim()));
      }
    }

    return widgets;
  }

  // 构建普通文本组件
  Widget _buildTextWidget(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.justify,
      ),
    );
  }

  // 构建引用卡片组件
  Widget _buildQuoteWidget(String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 1,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.primary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 大章节标题
          Text(
            '${bigChapter.bigChapterNumber}章 ${bigChapter.bigChapterTitle}',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          // 小章节标题
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '第${smallChapter.smallChapterNumber}节 ${smallChapter.smallChapterTitle}',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 分割线
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 24),

          // 解析后的内容
          ..._parseContent(smallChapter.content),

          const SizedBox(height: 48), // 底部留白
        ],
      ),
    );
  }
}
