import 'package:flutter/material.dart';

class CognitiveSwitchWidget extends StatefulWidget {
  const CognitiveSwitchWidget({super.key});

  @override
  State<CognitiveSwitchWidget> createState() => _CognitiveSwitchWidgetState();
}

class _CognitiveSwitchWidgetState extends State<CognitiveSwitchWidget> {
  bool _isActive = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 切换激活状态
        setState(() {
          _isActive = !_isActive;
        });
      },
      child: AnimatedContainer(
        // 添加状态变化动画
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Card(
          // 根据状态改变卡片样式
          color: _isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          elevation: _isActive ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: _isActive
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.book,
                  size: 28,
                  color: _isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondaryContainer,
                ),
                Text(
                  'deepseek',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: _isActive ? FontWeight.bold : FontWeight.normal,
                    color: _isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
