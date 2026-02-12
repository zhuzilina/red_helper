import 'package:flutter/material.dart';

class AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;

  const AchievementCard({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                achievement['icon'] as IconData,
                color: achievement['unlocked'] ? Colors.amber : Colors.grey[300],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                achievement['name'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: achievement['unlocked'] ? Colors.black : Colors.grey,
                  fontSize: 12,
                ),
              ),
              if (!achievement['unlocked'])
                const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}