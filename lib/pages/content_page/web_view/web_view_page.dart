import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentPage extends StatefulWidget {
  final String assetPath; // 改为资源路径参数
  final String title;

  const ContentPage({
    super.key,
    required this.assetPath,
    this.title = '本地内容',
  });

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  late final WebViewController controller;
  var isLoading = true;
  var hasError = false;
  var canGoBack = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() {
            isLoading = true;
            hasError = false;
          }),
          onPageFinished: (url) => setState(() {
            isLoading = false;
            controller.canGoBack().then((value) => canGoBack = value);
          }),
          onWebResourceError: (error) => setState(() => hasError = true),
        ),
      )
      ..setBackgroundColor(Colors.transparent)
      ..loadFlutterAsset(widget.assetPath); // 关键修改：加载资源文件
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _buildWebViewContent(),
    );
  }

  Widget _buildWebViewContent() {
    return Stack(
      children: [
        WebViewWidget(controller: controller),

        if (isLoading)
          const Center(child: CircularProgressIndicator()),

        if (hasError)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '无法加载本地资源: ${widget.assetPath}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => controller.reload(),
                  child: const Text('重新加载'),
                ),
              ],
            ),
          )
      ],
    );
  }
}