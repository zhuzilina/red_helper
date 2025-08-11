import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_helper/coze_page.dart';
import 'package:red_helper/pages/content_page/super_page/super_page.dart';

class MarkdownParserPage extends StatefulWidget {
  final String title;
  final String assetPath;
  final List<String> suggestions;

  const MarkdownParserPage({
    super.key,
    required this.title,
    required this.assetPath,
    required this.suggestions,
  });

  @override
  State<MarkdownParserPage> createState() => _MarkdownParserPageState();
}

class _MarkdownParserPageState extends State<MarkdownParserPage> {
  bool isHide = true;
  List<Widget> parsedContent = [];

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(widget.assetPath).then((value) {
      setState(() {
        parsedContent = parseMarkdown(value);
      });
    });
  }

  List<Widget> parseMarkdown(String content) {
    final lines = content.split('\n');
    final List<Widget> widgets = [];
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final double lineHeight = (textTheme.bodyLarge?.fontSize ?? 16) * 1.5;

    List<String> currentParagraph = [];
    List<String> currentQuote = [];
    bool inQuote = false;

    void finalizeParagraph() {
      if (currentParagraph.isNotEmpty) {
        final paragraphText = currentParagraph.join('\n');
        final textSpans = <TextSpan>[];
        final textParts = paragraphText.split('**');

        for (int i = 0; i < textParts.length; i++) {
          if (textParts[i].isEmpty) continue;

          textSpans.add(
            i % 2 == 1
                ? TextSpan(
                    text: textParts[i],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : TextSpan(text: textParts[i]),
          );
        }

        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: lineHeight),
            child: RichText(
              text: TextSpan(style: textTheme.bodyLarge, children: textSpans),
            ),
          ),
        );
        currentParagraph.clear();
      }
    }

    void finalizeQuote() {
      if (currentQuote.isNotEmpty) {
        final quoteText = currentQuote.join('\n');
        final textSpans = <TextSpan>[];
        final textParts = quoteText.split('**');

        for (int i = 0; i < textParts.length; i++) {
          if (textParts[i].isEmpty) continue;

          textSpans.add(
            i % 2 == 1
                ? TextSpan(
                    text: textParts[i],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : TextSpan(text: textParts[i]),
          );
        }

        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: lineHeight),
            child: Card(
              color: theme.colorScheme.surfaceVariant,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RichText(
                  text: TextSpan(
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    children: textSpans,
                  ),
                ),
              ),
            ),
          ),
        );
        currentQuote.clear();
        inQuote = false;
      }
    }

    // 优化后的引用行检测
    bool isQuoteLine(String line) {
      return line.trim().isNotEmpty && line.trim().startsWith('>');
    }

    // 改进的内容提取
    String extractQuoteContent(String line) {
      final content = line.replaceFirst(RegExp(r'^\s*>+\s*'), '');
      return content.trim();
    }

    for (var line in lines) {
      if (line.isEmpty) {
        if (inQuote) {
          currentQuote.add('');
        } else {
          finalizeParagraph();
        }
        continue;
      }

      if (isQuoteLine(line)) {
        finalizeParagraph(); // 确保结束任何在处理的段落

        // 处理可能的多层引用标记
        final quoteContent = extractQuoteContent(line);

        if (!inQuote) {
          // 新引用块开始
          inQuote = true;
        }
        currentQuote.add(quoteContent);
        continue;
      }

      if (inQuote) {
        // 当前在引用块中但遇到非引用行
        finalizeQuote();
      }

      // 处理其他元素
      if (line.startsWith('# ')) {
        finalizeParagraph();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 24, bottom: lineHeight),
            child: Text(line.substring(2), style: textTheme.headlineLarge),
          ),
        );
      } else if (line.startsWith('## ')) {
        finalizeParagraph();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: lineHeight),
            child: Text(line.substring(3), style: textTheme.headlineMedium),
          ),
        );
      } else if (line.startsWith('![')) {
        finalizeParagraph();
        final regex = RegExp(r'!\[(.*?)\]\((.*?)\)');
        final match = regex.firstMatch(line);
        if (match != null) {
          final description = match.group(1);
          final url = match.group(2);

          widgets.add(
            Column(
              children: [
                Image.network(url!, fit: BoxFit.cover, width: double.infinity),
                if (description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      description,
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        }
      } else if (line.startsWith('---')) {
        finalizeParagraph();
        widgets.add(const Divider());
      } else {
        // 普通文本添加到当前段落
        currentParagraph.add(line);
      }
    }

    // 处理剩余内容
    finalizeParagraph();
    finalizeQuote();

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: parsedContent.isNotEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: parsedContent,
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      // floatingActionButton: Stack(
      //   clipBehavior: Clip.none,
      //   children: [
      //     Positioned(
      //       bottom: 280,
      //       right: -35,
      //       child: DigitaPsersonFloatViewHome(
      //         suggestions: widget.suggestions,
      //         onTapSuggestion: () {},
      //       ),
      //     ),
      //   ],
      // ),
      floatingActionButtonLocation: ZeroMarginFABLocation(),
      floatingActionButton: FloatingActionMenu(
        imageAsset: 'assets/images/digital_person_1.png',
        options: [
          FloatingOption(
            label: '了解人物',
            icon: Icons.add,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SuperPage()),
              );
            },
            color: Colors.blue,
          ),
          FloatingOption(
            label: '了解兰考',
            icon: Icons.edit,
            onTap: () => print('点击了选项二'),
            color: Colors.green,
          ),
          FloatingOption(
            label: '了解理论',
            icon: Icons.delete,
            onTap: () => print('点击了选项三'),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class ZeroMarginFABLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 获取屏幕尺寸和按钮尺寸
    final double width = scaffoldGeometry.scaffoldSize.width;
    final double height = scaffoldGeometry.scaffoldSize.height;
    final double fabWidth = scaffoldGeometry.floatingActionButtonSize.width;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;

    // 计算安全区（可选）
    final double safePadding = scaffoldGeometry.minViewPadding.bottom;

    // 紧贴右下角（移除默认16px边距）
    return Offset(
      width - fabWidth, // 右侧无间距
      height - fabHeight - safePadding, // 底部无间距（但考虑安全区）
    );
  }
}

class FloatingActionMenu extends StatefulWidget {
  // 主图片资源
  final String imageAsset;
  // 选项列表
  final List<FloatingOption> options;
  // 主按钮大小
  final double buttonSize;
  // 选项按钮高度
  final double optionHeight;
  // 选项按钮宽度
  final double optionWidth;
  // 动画持续时间
  final Duration animationDuration;
  // 右侧距离
  final double rightOffset;

  const FloatingActionMenu({
    super.key,
    required this.imageAsset,
    required this.options,
    this.buttonSize = 60.0,
    this.optionHeight = 48.0,
    this.optionWidth = 120.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.rightOffset = 1.0, // 默认距离右侧24像素
  }) : assert(options.length == 3, "必须提供3个选项");

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class FloatingOption {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const FloatingOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = Colors.blue,
  });
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final GlobalKey _menuKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  final List<GlobalKey> _optionKeys = List.generate(3, (_) => GlobalKey());

  // 正确的展开位置计算器（左侧展开）
  List<Offset> get _expansionOffsets {
    const expansionRadius = 140.0; // 展开半径
    return [
      Offset(
        -expansionRadius * cos(pi / 4),
        -expansionRadius * sin(pi / 4),
      ), // 左上角45°
      Offset(-expansionRadius, 0), // 正左
      Offset(
        -expansionRadius * cos(pi / 4),
        expansionRadius * sin(pi / 4),
      ), // 左下角45°
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  bool _isPointInsideMenu(Offset globalPoint) {
    final screenSize = MediaQuery.of(context).size;
    final menuPosition = screenSize.height / 2 - widget.buttonSize / 2;

    // 主按钮区域
    final menuRect = Rect.fromLTWH(
      screenSize.width - widget.rightOffset - widget.buttonSize,
      menuPosition,
      widget.buttonSize,
      widget.buttonSize,
    );

    if (menuRect.contains(globalPoint)) {
      return true;
    }

    // 选项按钮区域
    final offsets = _expansionOffsets;
    for (var i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final optionRect = Rect.fromCircle(
        center: Offset(
          screenSize.width -
              widget.rightOffset -
              widget.buttonSize / 2 +
              offset.dx,
          menuPosition + widget.buttonSize / 2 + offset.dy,
        ),
        radius: max(widget.optionWidth, widget.optionHeight) / 2,
      );

      if (optionRect.contains(globalPoint)) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final menuPosition = screenSize.height / 3 - widget.buttonSize / 3;
    final expansionOffsets = _expansionOffsets;

    return Stack(
      children: [
        // 外部点击检测层
        if (_isOpen)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                if (!_isPointInsideMenu(event.position)) {
                  _toggleMenu();
                }
              },
            ),
          ),

        // 纯图片主按钮 - 去除了所有装饰效果
        Positioned(
          top: menuPosition,
          right: widget.rightOffset,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: SizedBox(
                width: 80,
                child: Image.asset(widget.imageAsset, fit: BoxFit.contain),
              ),
            ),
          ),
        ),

        // 选项按钮 - 在左侧展开
        ...List.generate(widget.options.length, (index) {
          return Positioned(
            top:
                menuPosition +
                widget.buttonSize / 2 +
                expansionOffsets[index].dy,
            left:
                screenSize.width -
                widget.rightOffset -
                widget.buttonSize / 2 +
                expansionOffsets[index].dx -
                widget.optionWidth / 2,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: IgnorePointer(
                ignoring: !_isOpen,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: _optionKeys[index],
                    onTap: () {
                      widget.options[index].onTap();
                      _toggleMenu();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: widget.optionWidth,
                      height: widget.optionHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: widget.options[index].color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.options[index].icon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.options[index].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
