import 'package:flutter/material.dart';

class QuizGrid extends StatelessWidget {
  final Function(String) onQuizPressed;

  const QuizGrid({super.key, required this.onQuizPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // 第一行 - 每日一答（大卡片）
          _buildLargeCard(
            context: context,
            title: '每日一答',
            color: Theme.of(context).colorScheme.surfaceContainer,
            icon: Icons.calendar_today,
            type: 'daily',
          ),
          const SizedBox(height: 12),
          // 第二行 - 两个小卡片
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: _buildSmallCard(
                    context: context,
                    title: '答题PK',
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    icon: Icons.people_alt,
                    type: 'pk',
                  )
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 120,
                  child:_buildSmallCard(
                    context: context,
                    title: '排行榜',
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    icon: Icons.leaderboard,
                    type: 'leaderboard',
                  ),
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeCard({
    required String title,
    required Color color,
    required IconData icon,
    required String type,
    required BuildContext context,
  }) {
    return _buildCard(
      context: context,
      height: 120,
      color: color,
      child: Row(
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.onSurface,),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Theme.of(context).colorScheme.onSurface)
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface),
        ],
      ),
      onTap: () => onQuizPressed(type),
    );
  }

  Widget _buildSmallCard({
    required String title,
    required Color color,
    required IconData icon,
    required String type,
    required BuildContext context,
  }) {
    return _buildCard(
      context: context,
      height: 100,
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),),
        ],
      ),
      onTap: () => onQuizPressed(type),
    );
  }

  Widget _buildCard({
    required double height,
    required Color color,
    required Widget child,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}