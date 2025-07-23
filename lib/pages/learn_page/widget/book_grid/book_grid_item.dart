import 'package:flutter/material.dart';
import 'package:red_helper/pages/content_page/web_view/web_view_page.dart';

class BookGridItem extends StatelessWidget {
  final String title;
  final String imageUrl;

  const BookGridItem({super.key, required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8), // 匹配 Card 的圆角
        onTap: () {
          // 跳转到书籍详情页，传递必要参数
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ContentPage(
                    assetPath: 'assets/html/pages/book.html',
                    title: title,
                  ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildBookCover(), _buildBookTitle()],
        ),
      ),
    );
  }

  Widget _buildBookCover() {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: Image.network(imageUrl, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBookTitle() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BookDetailPage extends StatelessWidget {
  final String title;
  final String imageUrl;

  const BookDetailPage({
    super.key,
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Image.network(imageUrl)),
    );
  }
}
