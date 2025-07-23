import 'package:flutter/material.dart';

class RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;

  const RewardCard({
    super.key,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Image.network(reward['image']! as String, height: 80, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${reward['points']}积分',
                    style: const TextStyle( fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}