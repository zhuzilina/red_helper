import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_helper/pages/learn_page/digita_pserson_float_view_home.dart';

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
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 280,
            right: -35,
            child: DigitaPsersonFloatViewHome(
              suggestions: widget.suggestions,
              onTapSuggestion: () {},
            ),
          ),
        ],
      ),
    );
  }
}
