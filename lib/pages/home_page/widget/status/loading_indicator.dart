import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double height;

  const LoadingIndicator({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
