// widgets/information_card.dart
import 'package:flutter/material.dart';
import 'package:red_helper/pages/content_page/article_page/article_page.dart';

class InformationCard extends StatelessWidget {
  final List<Map<String, dynamic>> newsItems;
  final ValueChanged<int>? onCategoryChanged;
  final int selectedCategoryIndex;

  const InformationCard({
    super.key,
    required this.newsItems,
    this.onCategoryChanged,
    this.selectedCategoryIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryMenu(context),
          const SizedBox(height: 15),
          _buildNewsList(),
        ],
      ),
    );
  }

  Widget _buildCategoryMenu(BuildContext context) {
    final categories = ['推荐', '党史', '理论'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => onCategoryChanged?.call(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: selectedCategoryIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                fontSize: selectedCategoryIndex == index ? 14 : 12,
                color: selectedCategoryIndex == index
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newsItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) => _NewsItemCard(item: newsItems[index]),
    );
  }
}

class _NewsItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _NewsItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 导航到详情页，传递当前资讯项数据
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarkdownParserPage(
              title: item['title']!,
              assetPath: item['path']!,
              suggestions: item['suggestions'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Image.network(
                item['cover']!,
                width: 120,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Placeholder(), // 错误处理
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['date']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
