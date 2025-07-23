import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
          SizedBox(width: 10),
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child:
                  widget.loadingText != null
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            strokeWidth: 3.0,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                          ),
                          const SizedBox(height: 12.0),
                          SelectableText(
                            widget.loadingText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14.0,
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

class CozePage extends StatefulWidget {
  const CozePage({super.key, required this.callMsg});
  final String callMsg;

  @override
  State<StatefulWidget> createState() {
    return _CozePage();
  }
}

class _CozePage extends State<CozePage> {
  // 控制器
  final TextEditingController inputController = TextEditingController();
  final ScrollController _controller = ScrollController();
  final ImagePicker _picker = ImagePicker();
  // 信号量
  bool isLoading = true;
  bool isSend = false;
  // 值-消息文本
  Msg? msg;
  List<Msg> messages = [];
  // 值-消息图片
  Uint8List? _selectedImage;
  String? imageId;

  void _handleSend() async {
    var msgItem = Msg(isUser: true, msg: '');
    String? copyImageId;
    if (_selectedImage != null) {
      await _saveImage();
      if (imageId != null) {
        copyImageId = imageId;
        print('文件保存成功：文件id:$imageId');
        msgItem.image = _selectedImage;
      }
    }
    final message = inputController.text.trim();
    if (message.isEmpty) return;
    // 创建发送信号控制状态
    setState(() {
      msgItem.msg = message;
      messages.add(msgItem);
      isLoading = true;
      isSend = true;
      inputController.clear();
      _deleteImage();
    });
    final data = await sendMessage(message, copyImageId);
    // 消息处理完成
    setState(() {
      messages.add(Msg(isUser: false, msg: data['content']));
      // 取消发送信号控制状态
      isLoading = false;
      isSend = false;
    });
    print(data['content']);
  }

  void _handleAddPicture() {
    _pickImageFromGallery();
  }

  void _deleteImage() {
    setState(() {
      _selectedImage = null;
      imageId = null;
    });
  }

  // 编译方法
  Widget compileMarkdown(String text) {
    return SizedBox();
  }

  // 异步方法
  // 获取图片
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  // 保存图片
  Future<void> _saveImage() async {
    const baseUrl = "http://121.36.87.174:3000";
    try {
      print('文件长度${_selectedImage!.length}');
      final url = Uri.parse('$baseUrl/api/upload/image');
      var request = http.MultipartRequest('POST', url);

      // 添加文件到请求
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _selectedImage!,
          filename: 'uploaded_image.jpg', // 提供文件名
          contentType: MediaType('image', 'jpeg'), // 指定内容类型
        ),
      );

      // 设置请求头
      request.headers['Content-Type'] = 'multipart/form-data';

      var response = await request.send();

      if (response.statusCode == 201) {
        print('上传成功');
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        imageId = jsonData['fileId'].toString();
        print('imageId:$imageId');
        print(jsonData);
      } else {
        print('上传失败${response.statusCode}${response.headers}');
        var errorData = await response.stream.bytesToString();
        print('错误详情: $errorData');
      }
    } catch (e) {
      print('错误$e');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String msg, String? fileId) async {
    var url = Uri.parse('http://121.36.87.174:3000/?msg=$msg');
    if (fileId != null) {
      url = Uri.parse('http://121.36.87.174:3000/?msg=$msg&file_id=$fileId');
    }
    try {
      print('开始发送');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        throw ('请求失败:${response.body}');
      }
    } catch (e) {
      throw ("发生了错误:$e");
    }
  }

  @override
  void initState() {
    super.initState();
    inputController.text = widget.callMsg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: SelectableText('小红同学')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              child: SingleChildScrollView(
                controller: _controller,
                child: Column(
                  children: [
                    ...messages.map(
                      (item) => MsgCard(
                        isUserType: item.isUser,
                        msg: item.msg,
                        image: item.image,
                      ),
                    ),
                    LoadingAnimation(isLoading: isLoading && isSend),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                _selectedImage == null
                    ? TextButton(
                      onPressed: () {
                        _handleAddPicture();
                      },
                      child: SelectableText('添加图片'),
                    )
                    : SizedBox(
                      height: 60,
                      width: 60,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_selectedImage!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.delete_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 0, 10),
              child: Row(
                spacing: 7,
                children: [
                  SizedBox(
                    height: 40,
                    width: 240,
                    child: TextField(
                      controller: inputController,
                      autofocus: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(40)),
                        ),
                        hint: SelectableText(
                          '向小红同学提问',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _handleSend();
                    },
                    child: SelectableText('发送'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MsgCard extends StatefulWidget {
  const MsgCard({
    super.key,
    required this.isUserType,
    required this.msg,
    required this.image,
  });
  final bool isUserType;
  final String msg;
  final Uint8List? image;

  @override
  State<MsgCard> createState() => _MsgCardState();
}

class _MsgCardState extends State<MsgCard> {
  // late final WebViewController _controller;

  // @override
  // void initState() {
  //   super.initState();
  //   if (!widget.isUserType) {
  //     _controller =
  //         WebViewController()
  //           ..setJavaScriptMode(JavaScriptMode.disabled)
  //           ..loadHtmlString(widget.msg);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          widget.isUserType ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        SizedBox(width: 7),
        SizedBox(
          width: 300,
          child:
              widget.isUserType
                  ? Card(
                    color:
                        widget.isUserType
                            ? Theme.of(context).colorScheme.surfaceContainer
                            : Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.image != null
                              ? SizedBox(
                                width: 280,
                                child: Image.memory(
                                  widget.image!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : SizedBox(height: 1),
                          SelectableText(widget.msg),
                        ],
                      ),
                    ),
                  )
                  : SizedBox(
                    width: 300,
                    child: MarkdownCompleteWidget(content: widget.msg),
                  ),
        ),
      ],
    );
  }
}

class Msg {
  bool isUser;
  String msg;
  Uint8List? image;
  Msg({required this.isUser, required this.msg});
}

class MarkdownCompleteWidget extends StatelessWidget {
  final String content;

  const MarkdownCompleteWidget({super.key, required this.content});

  // 解析整个文档为Widget列表
  List<Widget> _parseDocument() {
    final widgets = <Widget>[];
    // 分割各个###标题部分
    final sections = content.split(RegExp(r'\n### '));

    // 处理标题前的内容
    if (sections.isNotEmpty && sections[0].isNotEmpty) {
      widgets.add(_parseContentBlock(sections[0]));
      widgets.add(const SizedBox(height: 24));
    }

    // 处理每个标题区块
    for (var i = 1; i < sections.length; i++) {
      final section = sections[i];
      if (section.isEmpty) continue;

      // 分割标题和内容
      final firstNewlineIndex = section.indexOf('\n');
      if (firstNewlineIndex == -1) {
        widgets.add(_buildHeading(section));
        continue;
      }

      final title = section.substring(0, firstNewlineIndex);
      final content = section.substring(firstNewlineIndex + 1);

      widgets.add(_buildHeading(title));
      widgets.add(_parseContentBlock(content));
      widgets.add(const SizedBox(height: 24));
    }

    return widgets;
  }

  // 构建标题Widget
  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B0000),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // 解析内容块（处理列表、图片和普通文本）
  Widget _parseContentBlock(String content) {
    // 按行分割内容
    final lines = content.split('\n');
    final widgets = <Widget>[];
    List<Widget>? listItems; // 用于收集列表项

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        // 空行：如果正在处理列表，则结束列表
        if (listItems != null) {
          widgets.add(_buildList(listItems));
          listItems = null;
        }
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // 检查是否是图片（![描述](url)格式）
      final imageMatch = RegExp(r'!\[(.*?)\]\((.*?)\)').firstMatch(trimmedLine);
      if (imageMatch != null) {
        // 如果正在处理列表，则先结束列表
        if (listItems != null) {
          widgets.add(_buildList(listItems));
          listItems = null;
        }

        final altText = imageMatch.group(1) ?? '图片';
        final imageUrl = imageMatch.group(2) ?? '';

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _buildImageWidget(imageUrl, altText),
          ),
        );
        continue;
      }

      // 检查是否是列表项（以-开头）
      if (trimmedLine.startsWith('- ')) {
        final textContent = trimmedLine.substring(2).trim();
        // 如果不在列表中，开始新列表
        if (listItems == null) {
          listItems = [];
        }
        // 解析列表项中的加粗文本并添加到列表
        listItems.add(_parseRichText(textContent));
      } else {
        // 普通文本：如果正在处理列表，则先结束列表
        if (listItems != null) {
          widgets.add(_buildList(listItems));
          listItems = null;
        }
        // 解析普通文本中的加粗部分
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _parseRichText(trimmedLine),
          ),
        );
      }
    }

    // 处理剩余的列表项
    if (listItems != null) {
      widgets.add(_buildList(listItems));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // 构建列表Widget
  Widget _buildList(List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFF8B0000), fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: item),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  // 构建图片Widget
  Widget _buildImageWidget(String url, String altText) {
    print('url 这个url:$url');
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder:
                (context, url) => const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          '无法加载图片: $altText',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 240,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            altText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // 解析文本中的加粗部分（**内容**）
  Widget _parseRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    // 查找所有加粗文本并构建TextSpan
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        );
      }

      // 添加加粗文本
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // 添加剩余文本
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseDocument(),
      ),
    );
  }
}
