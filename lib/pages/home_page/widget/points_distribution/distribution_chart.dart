import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:red_helper/repository/models/model.dart';
import 'chart_legend.dart';

class PointsDistributionChart extends StatelessWidget {
  final List<PointsCategory> categories;

  const PointsDistributionChart({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final totalPoints = categories.fold<int>(
      0,
      (sum, item) => sum + item.points,
    );

    return Stack(children: [_buildContent(totalPoints)]);
  }

  Widget _buildContent(int totalPoints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xeef5eede), Color(0xaaf1c385)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x99fcedea), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Text(
              '积分分布',
              style: TextStyle(
                fontFamily: 'blockLetter',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          _buildChart(totalPoints),
        ],
      ),
    );
  }

  Widget _buildChart(int totalPoints) {
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections:
                    categories
                        .map(
                          (item) => PieChartSectionData(
                            color: item.color,
                            value: item.points.toDouble(),
                            title: item.category,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ChartLegend(
              categories: categories,
              totalPoints: totalPoints,
            ),
          ),
        ],
      ),
    );
  }
}
