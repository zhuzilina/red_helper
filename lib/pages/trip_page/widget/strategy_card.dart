import 'package:flutter/material.dart';
import 'package:red_helper/pages/content_page/web_view/web_view_page.dart';

class StrategyCard extends StatelessWidget {
  final Map<String, dynamic> strategy;

  const StrategyCard({super.key, required this.strategy});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ContentPage(
                    assetPath: 'assets/html/pages/strategy.html',
                    title: '遵义会议会址旅游攻略',
                  ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                strategy['image'].toString(),
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy['title'].toString(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(
                          'https://picsum.photos/50?random=5',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '旅行达人',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        strategy['likes'].toString(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
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
