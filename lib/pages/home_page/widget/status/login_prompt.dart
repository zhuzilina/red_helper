import 'package:flutter/material.dart';

class LoginPrompt extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const LoginPrompt({super.key, required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('请登录'),
        ElevatedButton(onPressed: onLoginPressed, child: const Text('点击登录')),
      ],
    );
  }
}
