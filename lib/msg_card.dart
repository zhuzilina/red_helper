import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:red_helper/coze_page.dart';
import 'package:red_helper/markdown_complete_widget.dart';

class MsgCard extends StatefulWidget {
  const MsgCard({
    super.key,
    required this.isUserType,
    required this.msg,
    required this.image,
    required this.width,
  });
  final bool isUserType;
  final String msg;
  final Uint8List? image;
  final double width;

  @override
  State<MsgCard> createState() => _MsgCardState();
}

class _MsgCardState extends State<MsgCard> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.isUserType
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        SizedBox(width: 7),
        widget.isUserType
            ? Card(
                color: widget.isUserType
                    ? Theme.of(context).colorScheme.surfaceContainer
                    : Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: EdgeInsets.all(7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.image != null
                          ? SizedBox(
                              width: widget.width * 0.6,
                              child: Image.memory(
                                widget.image!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : SizedBox(height: 1),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: widget.width * 0.7,
                        ),
                        child: SelectableText(widget.msg),
                      ),
                    ],
                  ),
                ),
              )
            : Card(
                child: SizedBox(
                  width: widget.width * 0.95,
                  child: MarkdownCompleteWidget(content: widget.msg),
                ),
              ),
      ],
    );
  }
}
