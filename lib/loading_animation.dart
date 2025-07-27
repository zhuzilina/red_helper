import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final bool isLoading;
  final String? loadingText;
  final double size;

  const LoadingAnimation({
    super.key,
    required this.isLoading,
    this.loadingText,
    this.size = 40.0,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 根据初始加载状态设置动画值
    if (widget.isLoading) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 监听加载状态变化并控制动画
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _fadeController,
      child: Row(
        children: [
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: widget.loadingText != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          strokeWidth: 2.0,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                        ),
                        SelectableText(
                          widget.loadingText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      strokeWidth: 3.0,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
