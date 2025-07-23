import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutButton({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('退出登录'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onLogout,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}