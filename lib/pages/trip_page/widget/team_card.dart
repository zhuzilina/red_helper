import 'package:flutter/material.dart';
import 'package:red_helper/pages/content_page/web_view/web_view_page.dart';

class TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;

  const TeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ContentPage(
                  assetPath: 'assets/html/pages/team_up.html',
                  title: '遵义会议会址旅游攻略',
                ),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(team['avatar'].toString()),
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team['name'].toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('时间：${team['date']}'),
                      Text('已有${team['members']}人参加'),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.group_add)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
