import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraReady = false;
  final bool _isRecording = false;
  FlashMode _flashMode = FlashMode.off;
  CameraLensDirection _direction = CameraLensDirection.back;
  final double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        widget.cameras.firstWhere(
          (camera) => camera.lensDirection == _direction,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller.initialize().then((_) async {
        if (!mounted) return;
        _controller.setFlashMode(_flashMode);
        setState(() => _isCameraReady = true);
      });
    } catch (e) {
      _showErrorDialog('相机初始化失败: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 新增：取消所有可能的观察者订阅（根据插件文档调整）
    _controller.dispose().then((_) {
      // 确保释放完成后再执行后续操作
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.value.isInitialized) {
        _initializeCamera(); // 仅在未初始化时重新初始化
      }
    } else if (state == AppLifecycleState.paused) {
      // 延迟释放资源，避免与页面切换动画冲突
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.dispose();
      });
    }
  }

  Future<String> _takePicture() async {
    try {
      if (!_controller.value.isInitialized) {
        throw CameraException('相机未就绪', '请等待相机初始化完成');
      }

      final Directory extDir = await getTemporaryDirectory();
      final String filePath =
          '${extDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (_controller.value.isTakingPicture) {
        return '';
      }

      try {
        XFile file = await _controller.takePicture();
        await file.saveTo(filePath);
        return filePath;
      } on CameraException catch (e) {
        _showErrorDialog('拍摄失败: ${e.description}');
        return '';
      }
    } on CameraException catch (e) {
      _showErrorDialog('拍摄失败: ${e.description}');
      return '';
    } on PlatformException catch (e) {
      _showErrorDialog('系统错误: ${e.message}');
      return '';
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _controller.setFlashMode(_flashMode);
    });
  }

  void _switchCamera() async {
    try {
      setState(() => _isCameraReady = false);
      await _controller.dispose();
      _direction =
          _direction == CameraLensDirection.back
              ? CameraLensDirection.front
              : CameraLensDirection.back;
      await _initializeCamera();
    } catch (e) {
      _showErrorDialog('切换摄像头失败: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('错误'),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('确定'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 替换闪光灯按钮为返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6.0),
              child: const Text(
                '×',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.switch_camera,
              color: Colors.white,
              size: 32,
            ),
            onPressed: _switchCamera,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildTopControls(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_controller.value.isInitialized) {
      return const SizedBox.expand(); // 未初始化时填充整个屏幕
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceRatio = _controller.value.aspectRatio;
        return OverflowBox(
          alignment: Alignment.center,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          child: AspectRatio(
            aspectRatio: deviceRatio,
            child: Transform.scale(
              // 传递constraints参数给计算函数
              scale: _getScaleFactor(deviceRatio, constraints),
              child: CameraPreview(_controller),
            ),
          ),
        );
      },
    );
  }

  // 修正：添加BoxConstraints参数
  double _getScaleFactor(double deviceRatio, BoxConstraints constraints) {
    final screenRatio = constraints.maxWidth / constraints.maxHeight;

    if (deviceRatio > screenRatio) {
      // 相机比例更宽：垂直方向缩放至满屏，水平方向裁剪
      return constraints.maxHeight / (constraints.maxWidth / deviceRatio);
    } else {
      // 相机比例更高：水平方向缩放至满屏，垂直方向裁剪
      return constraints.maxWidth / (constraints.maxHeight * deviceRatio);
    }
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Center(
          child: GestureDetector(
            onTap: () async {
              final path = await _takePicture();
              if (path.isNotEmpty) {
                Navigator.pop(context, path);
              }
            },
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
