import 'package:flutter/material.dart';

class LoginSettingItem extends StatelessWidget {
  final VoidCallback onLogin;

  const LoginSettingItem({
    super.key,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.login),
        title: const Text('登录账户'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onLogin,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}