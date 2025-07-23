import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final bool isLoggedIn;
  final Map<String, dynamic> userInfo;
  final VoidCallback onLogin;

  const ProfileCard({
    super.key,
    required this.isLoggedIn,
    required this.userInfo,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return isLoggedIn ? _buildLoggedInProfile() : _buildLoginPrompt();
  }

  Widget _buildLoggedInProfile() {
    return Stack(
      children: [
        Image.network(
          userInfo['background']! as String,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(userInfo['avatar']! as String),
                  radius: 40,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userInfo['nickname']! as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                Text(
                  '🎂 ${userInfo['birthday']}',
                ),
                const SizedBox(height: 8),
                Text(
                  userInfo['bio']! as String,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '请登录查看个人信息',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('立即登录'),
            ),
          ],
        ),
      ),
    );
  }
}