import 'package:flutter/material.dart';
import 'package:red_helper/repository/models/model.dart';
import 'package:red_helper/pages/learn_page/widget/common/safe_image.dart';

class CarouselItem extends StatelessWidget {
  final Book book;

  const CarouselItem({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [_buildBookCover(), _buildGradientOverlay(), _buildBookTitle()],
    );
  }

  Widget _buildBookCover() {
    return SafeNetworkImage(imageUrl: book.coverUrl, fit: BoxFit.cover);
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildBookTitle() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          book.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
