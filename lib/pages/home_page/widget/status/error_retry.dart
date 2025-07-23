import 'package:flutter/material.dart';

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final double height;

  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('数据加载失败: $message'),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
