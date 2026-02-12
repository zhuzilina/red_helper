import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentWidget extends StatefulWidget {
  final String assetPath;  // 修改参数名为 assetPath 以明确用途

  const ContentWidget({
    super.key,
    required this.assetPath,  // 要求传入 assets 路径
  });

  @override
  State<ContentWidget> createState() => _ContentWidgetState();
}

class _ContentWidgetState extends State<ContentWidget> {
  late final WebViewController controller;
  var isLoading = true;
  var hasError = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => isLoading = true),
          onPageFinished: (url) => setState(() => isLoading = false),
          onWebResourceError: (error) => setState(() => hasError = true),
        ),
      )
      ..loadFlutterAsset(widget.assetPath);  // 使用加载本地资源的方法
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            WebViewWidget(controller: controller),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
            if (hasError)
              const Center(
                child: Icon(Icons.error, color: Colors.red),
              )
          ],
        );
      },
    );
  }
}