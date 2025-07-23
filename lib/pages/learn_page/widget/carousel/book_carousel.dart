import 'package:flutter/material.dart';
import 'package:red_helper/repository/models/model.dart';
import 'package:red_helper/pages/learn_page/widget/carousel/carousel_item.dart';

class BookCarousel extends StatelessWidget {
  final List<Book> books;
  final bool isLoading;

  const BookCarousel({super.key, required this.books, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: 150, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (books.isEmpty) {
      return Image.asset('assets/images/bg.png', fit: BoxFit.cover);
    }
    return PageView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) => CarouselItem(book: books[index]),
    );
  }
}
