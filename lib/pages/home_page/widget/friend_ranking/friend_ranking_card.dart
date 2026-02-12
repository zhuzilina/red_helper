import 'package:flutter/material.dart';
import 'package:red_helper/repository/models/model.dart';
import 'friend_list_item.dart';

class FriendRankingCard extends StatelessWidget {
  final List<Friend> friends;

  const FriendRankingCard({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 5),
      decoration: _buildCardDecoration(),
      child: SizedBox(
        height: 115,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemExtent: 125,
          itemCount: friends.length,
          itemBuilder:
              (context, index) =>
                  FriendListItem(friend: friends[index], rank: index + 1),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xeef5eede), Color(0xb2f6cc93)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0xeffcedea), blurRadius: 8)],
    );
  }
}
