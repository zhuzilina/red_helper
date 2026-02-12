import 'package:flutter/material.dart';

class DateGrid extends StatelessWidget {
  const DateGrid({super.key});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 120,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: 6 - index));
          final isToday = _isSameDay(date, today);

          return Container(
            constraints: const BoxConstraints(maxHeight: 80),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday ? Colors.red : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: _getRewardIcon(index),
                ),
                Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getRewardIcon(int index) {
    final rewards = [
      Icons.star_border,
      Icons.card_giftcard,
      Icons.attach_money,
      Icons.diamond,
      Icons.workspace_premium,
      Icons.card_giftcard,
      Icons.star,
    ];

    return Icon(rewards[index], size: 16, color: Colors.orange);
  }
}
