import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MarkdownCompleteWidget extends StatelessWidget {
  final String content;

  const MarkdownCompleteWidget({super.key, required this.content});

  // 解析整个文档为Widget列表
  List<Widget> _parseDocument() {
    final widgets = <Widget>[];
    // 分割各个###标题部分
    final sections = content.split(RegExp(r'\n### '));

    // 处理标题前的内容
    if (sections.isNotEmpty && sections[0].isNotEmpty) {
      widgets.add(_parseContentBlock(sections[0]));
      widgets.add(const SizedBox(height: 12));
    }

    // 处理每个标题区块
    for (var i = 1; i < sections.length; i++) {
      final section = sections[i];
      if (section.isEmpty) continue;

      // 分割标题和内容
      final firstNewlineIndex = section.indexOf('\n');
      if (firstNewlineIndex == -1) {
        widgets.add(_buildHeading(section));
        continue;
      }

      final title = section.substring(0, firstNewlineIndex);
      final content = section.substring(firstNewlineIndex + 1);

      widgets.add(_buildHeading(title));
      widgets.add(_parseContentBlock(content));
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  // 构建标题Widget
  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B0000),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // 解析内容块（处理列表、图片和普通文本）
  Widget _parseContentBlock(String content) {
    // 按行分割内容
    final lines = content.split('\n');
    final widgets = <Widget>[];
    List<Widget>? listItems; // 用于收集列表项

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        // 空行：如果正在处理列表，则结束列表
        if (listItems != null) {
          widgets.add(_buildList(listItems));
          listItems = null;
        }
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // 检查是否是图片（![描述](url)格式）
      final imageMatch = RegExp(r'!\[(.*?)\]\((.*?)\)').firstMatch(trimmedLine);
      if (imageMatch != null) {
        // 如果正在处理列表，则先结束列表
        if (listItems != null) {
          widgets.add(_buildList(listItems));
          listItems = null;
        }

        final altText = imageMatch.group(1) ?? '图片';
        final imageUrl = imageMatch.group(2) ?? '';

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildImageWidget(imageUrl, altText),
          ),
        );
        continue;
      }

      // 检查是否是列表项（以-开头）
      if (trimmedLine.startsWith('- ')) {
        final textContent = trimmedLine.substring(2).trim();
        // 如果不在列表中，开始新列表
        if (listItems == null) {
          listItems = [];
        }
        // 解析列表项中的加粗文本并添加到列表
        listItems.add(_parseRichText(textContent));
      } else {
        // 普通文本：如果正在处理列表，则先结束列表
        if (listItems != null) {
          widgets.add(_buildList(listItems));
          listItems = null;
        }
        // 解析普通文本中的加粗部分
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _parseRichText(trimmedLine),
          ),
        );
      }
    }

    // 处理剩余的列表项
    if (listItems != null) {
      widgets.add(_buildList(listItems));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // 构建列表Widget
  Widget _buildList(List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•',
                  style: TextStyle(color: Color(0xFF8B0000), fontSize: 16),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(width: 8),
                Expanded(child: item),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 构建图片Widget
  Widget _buildImageWidget(String url, String altText) {
    print('url 这个url:$url');
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (context, url) => const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      '无法加载图片: $altText',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 240,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            altText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // 解析文本中的加粗部分（**内容**）
  Widget _parseRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    // 查找所有加粗文本并构建TextSpan
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        );
      }

      // 添加加粗文本
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // 添加剩余文本
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseDocument(),
      ),
    );
  }
}
