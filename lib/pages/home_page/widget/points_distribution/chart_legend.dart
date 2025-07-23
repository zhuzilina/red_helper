import 'package:flutter/material.dart';
import 'package:red_helper/repository/models/model.dart';

class ChartLegend extends StatelessWidget {
  final List<PointsCategory> categories;
  final int totalPoints;

  const ChartLegend({
    super.key,
    required this.categories,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Color(0x33ffffff),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...categories.map((category) => _buildLegendItem(category))],
      ),
    );
  }

  Widget _buildLegendItem(PointsCategory category) {
    final percentage = (category.points / totalPoints * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.rectangle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(category.category)),
          Text('$percentage%'),
          //const SizedBox(width: 20),
        ],
      ),
    );
  }
}
