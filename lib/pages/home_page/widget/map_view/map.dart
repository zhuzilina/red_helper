import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AchievementRoadmap extends StatefulWidget {
  final String url;  // 新增 url 参数

  const AchievementRoadmap({
    super.key,
    required this.url,
  });

  @override
  State<AchievementRoadmap> createState() => _AchievementRoadmapState();
}

class _AchievementRoadmapState extends State<AchievementRoadmap> {
  late final WebViewController controller;
  var isLoading = true;  // 跟踪加载状态
  var hasError = false;  // 跟踪错误状态

  @override
  void initState() {
    super.initState();

    // 初始化 WebViewController
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => isLoading = true),
          onPageFinished: (url) => setState(() => isLoading = false),
          onWebResourceError: (error) => setState(() => hasError = true),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder( // 添加布局约束
        builder: (context, constraints) {
      return Stack(
          children: [
            WebViewWidget(controller: controller),
            // 加载指示器
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
            // 错误提示
            if (hasError)
              const Center(
                child: Icon(Icons.error, color: Colors.red, size: 50),
              )
      ],
    );
  });
}
}