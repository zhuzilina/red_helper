import 'package:flutter/material.dart';

class MoreButton extends StatelessWidget {
  const MoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => print('加载更多书籍'),
      child:Container(
        padding: EdgeInsets.all(20),
        child: Text(
          '查看更多',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.secondary)
        ),
      ));
  }
}