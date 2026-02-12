import 'package:flutter/material.dart';
import 'package:red_helper/repository/models/model.dart';
import 'package:red_helper/pages/content_page/web_view/web_view_page.dart';

class FriendListItem extends StatelessWidget {
  final Friend friend;
  final int rank;

  const FriendListItem({super.key, required this.friend, required this.rank});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150),
      child: InkWell(
        onTap:
            () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ContentPage(
                        assetPath: 'assets/html/pages/user_content.html',
                        title: '张四的个人主页',
                      ),
                ),
              ),
            },
        child: Column(
          children: [
            Stack(
              children: [
                _buildAvatar(),
                _buildRankBadge(),
                _buildCornerBadge(),
              ],
            ),
            _buildUserName(),
            _buildPointsDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0xeffcedea), blurRadius: 8)],
      ),
      child: ClipOval(
        child: Image.network(
          friend.avatarUrl,
          errorBuilder: (_, __, ___) => const Icon(Icons.person),
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    final isTopThree = rank <= 3;
    final medalColors = [
      const Color(0xFFF67FB9),
      const Color(0xFF42D8F9),
      const Color(0xFF67E8A1),
    ];

    return Positioned(
      top: 8,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: isTopThree ? medalColors[rank - 1] : Colors.blue[200],
        child: Text(
          '$rank',
          style: TextStyle(
            color: isTopThree ? Colors.white : Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCornerBadge() {
    return Positioned(
      right: 8, // 左侧间距
      bottom: 0, // 底部间距
      child: Container(
        alignment: Alignment.center,
        color: Color(0xfff9957f),
        width: 24, // 宽度
        height: 12, // 高度

        child: Text(
          '称号',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 8, // 可选的字体大小调整
          ),
        ),
      ),
    );
  }

  Widget _buildUserName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        friend.nikename,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildPointsDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${friend.points}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xffeb6c3a),
            ),
          ),
          Text(' 积分', style: TextStyle(fontSize: 11, color: Color(0xffeb6c3a))),
        ],
      ),
    );
  }
}
