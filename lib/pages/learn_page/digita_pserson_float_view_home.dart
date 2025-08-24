import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_helper/pages/coze_page/coze_page.dart';
import 'package:red_helper/pages/learn_page/widget/common/safe_image.dart';

class DigitaPsersonFloatViewHome extends StatefulWidget {
  const DigitaPsersonFloatViewHome({
    super.key,
    required this.onTapSuggestion,
    required this.suggestions,
  });
  final Function() onTapSuggestion;
  final List<String> suggestions;

  @override
  State<DigitaPsersonFloatViewHome> createState() =>
      _DigitaPsersonFloatViewHomeState();
}

class _DigitaPsersonFloatViewHomeState
    extends State<DigitaPsersonFloatViewHome> {
  // 状态
  bool isLoading = false;
  int _currentIndex = 0;
  late String currentMsg;
  Timer? _timer;
  // 新增动画相关状态
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    if (widget.suggestions.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
        // 开始动画
        setState(() {
          _isAnimating = true;
        });

        // 动画结束后更新索引并重置动画状态
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _currentIndex = (_currentIndex + 1) % widget.suggestions.length;
              _isAnimating = false;
            });
          }
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant DigitaPsersonFloatViewHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.suggestions, oldWidget.suggestions)) {
      _currentIndex = 0;
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 300,
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          GestureDetector(
            onTap: () => showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext context) {
                return LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight * 0.9,
                    child: ClipRRect(child: CozePage(callMsg: '')),
                  ),
                );
              },
            ),
            child: SizedBox(
              width: 100,
              child: Column(
                children: [
                  SafeAssetImage(
                    assetPath: 'assets/images/digital_person_1.png',
                  ),
                ],
              ),
            ),
          ),

          if (isLoading)
            Positioned(
              left: 70,
              top: 60,
              child: SizedBox(
                width: 70,
                child: QuickStart(
                  callMsg: currentMsg,
                  callback: () {
                    setState(() {
                      isLoading = false;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    this.speed = const Duration(milliseconds: 100),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late String _displayedText;
  late int _currentPosition;

  @override
  void initState() {
    super.initState();
    _displayedText = '';
    _currentPosition = 0;
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果文本内容变化，重新开始打字动画
    if (oldWidget.text != widget.text) {
      _displayedText = '';
      _currentPosition = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    if (_currentPosition < widget.text.length) {
      Future.delayed(widget.speed, () {
        if (mounted) {
          setState(() {
            _currentPosition++;
            _displayedText = widget.text.substring(0, _currentPosition);
          });
          _startTyping();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, maxLines: null);
  }
}
