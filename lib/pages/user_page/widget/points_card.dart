import 'package:flutter/material.dart';

import '../../../route/routes.dart';

class PointsCard extends StatelessWidget {
  final int points;

  const PointsCard({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '我的积分',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                points.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, RoutePath.exchange),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('兑换奖品'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}