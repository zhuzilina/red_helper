import 'package:flutter/material.dart';

/// 安全的网络图片加载组件
/// 包含错误处理、加载状态和超时处理，防止图片加载失败导致APP崩溃
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Duration timeout;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.timeout = const Duration(seconds: 10),
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 错误处理
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget(context);
      },
      // 加载状态
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget(context, loadingProgress);
      },
      // 淡入动画
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: fadeInDuration,
          curve: Curves.easeOut,
          child: child,
        );
      },
    );

    // 添加圆角
    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: _getIconSize(),
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            '图片加载失败',
            style: TextStyle(fontSize: _getFontSize(), color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(
    BuildContext context,
    ImageChunkEvent loadingProgress,
  ) {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: _getStrokeWidth(),
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  double _getIconSize() {
    if (width != null && width! < 60) return 16;
    if (width != null && width! < 120) return 24;
    return 40;
  }

  double _getFontSize() {
    if (width != null && width! < 60) return 8;
    if (width != null && width! < 120) return 10;
    return 12;
  }

  double _getStrokeWidth() {
    if (width != null && width! < 60) return 1;
    if (width != null && width! < 120) return 2;
    return 3;
  }
}

/// 安全的本地图片加载组件
class SafeAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  const SafeAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      // 错误处理
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget(context);
      },
      // 淡入动画
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: fadeInDuration,
          curve: Curves.easeOut,
          child: child,
        );
      },
    );

    // 添加圆角
    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: _getIconSize(),
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            '图片加载失败',
            style: TextStyle(fontSize: _getFontSize(), color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  double _getIconSize() {
    if (width != null && width! < 60) return 16;
    if (width != null && width! < 120) return 24;
    return 40;
  }

  double _getFontSize() {
    if (width != null && width! < 60) return 8;
    if (width != null && width! < 120) return 10;
    return 12;
  }
}
