import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int continuousDays;

  const ProgressBar({super.key, required this.continuousDays});

  @override
  Widget build(BuildContext context) {
    const maxDays = 14;
    final progress = continuousDays / maxDays;

    return Stack(
      children: [
        Container(
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          width: MediaQuery.of(context).size.width * 0.8 * progress,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
