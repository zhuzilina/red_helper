import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:red_helper/env.dart';
import 'package:red_helper/repository/models/msg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:url_launcher/url_launcher.dart';

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
              child: widget.loadingText != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          strokeWidth: 3.0,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
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
  final ScrollController _scrollController = ScrollController();
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
      _scrollToBottom();
    });
    final service = CozeStreamService(msg: message);

    print('创建流订阅...');
    bool isFirstDeltaReceived = false; // 标记是否收到第一个增量

    final streamSubscription = service.sendStreamRequest().listen((event) {
      print('收到事件: ${event.type}');

      switch (event.type) {
        case CozeEventType.conversationMessageDelta:
          final message = event.data as CozeMessage;
          print('增量内容: ${message.content}');

          // 收到第一个增量内容时关闭加载动画
          if (!isFirstDeltaReceived) {
            setState(() {
              isLoading = false;
              isSend = true;
              isFirstDeltaReceived = true;
            });
          }

          // 实时更新最后一条机器人消息
          setState(() {
            if (messages.isNotEmpty && !messages.last.isUser) {
              // 更新现有消息
              messages.last = Msg(
                isUser: false,
                msg: service.fullAnswer, // 使用累积的完整内容
              );
              _scrollToBottom();
            } else {
              // 防止异常情况，添加新消息
              messages.add(Msg(isUser: false, msg: service.fullAnswer));
            }
          });
          break;

        case CozeEventType.conversationMessageCompleted:
          final message = event.data as CozeMessage;
          print('消息完成: ${message.content}');
          // 确保最终内容正确显示
          setState(() {
            if (messages.isNotEmpty && !messages.last.isUser) {
              messages.last = Msg(isUser: false, msg: service.fullAnswer);
            }
          });
          break;

        case CozeEventType.conversationChatCompleted:
          final chat = event.data as CozeChatCompleted;
          print('聊天完成，耗时: ${chat.completedAt - chat.createdAt}ms');
          print('完整回答: ${service.fullAnswer}');
          // 最终状态更新
          setState(() {
            isLoading = false;
            isSend = false;
          });
          break;

        case CozeEventType.done:
          print('流结束: ${event.data}');
          break;

        default:
          print('未知事件: ${event.type}');
      }
    });

    streamSubscription.onError((error) {
      print('发生错误: $error');
      setState(() {
        isLoading = false;
        isSend = false;
        // 显示错误消息
        if (messages.isNotEmpty && !messages.last.isUser) {
          messages.last = Msg(isUser: false, msg: '加载失败，请重试');
        } else {
          messages.add(Msg(isUser: false, msg: '加载失败，请重试'));
        }
      });
    });

    streamSubscription.onDone(() {
      print('请求处理完成');
      setState(() {
        isLoading = false;
        isSend = false;
        _saveMessages();
      });
    });
    // var msgItem = Msg(isUser: true, msg: '');
    // String? copyImageId;
    // if (_selectedImage != null) {
    //   await _saveImage();
    //   if (imageId != null) {
    //     copyImageId = imageId;
    //     print('文件保存成功：文件id:$imageId');
    //     msgItem.image = _selectedImage;
    //   }
    // }
    // final message = inputController.text.trim();
    // if (message.isEmpty) return;
    // // 创建发送信号控制状态
    // setState(() {
    //   msgItem.msg = message;
    //   messages.add(msgItem);
    //   isLoading = true;
    //   isSend = true;
    //   inputController.clear();
    //   _deleteImage();
    // });
    // final data = await sendMessage(message, copyImageId);
    // // 消息处理完成
    // setState(() {
    // messages.add(Msg(isUser: false, msg: data['content']));
    // // 取消发送信号控制状态
    // isLoading = false;
    // isSend = false;
    // });
    // print(data['content']);
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

  // 焦点同步方法
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        // 如果你想要平滑滚动，可以使用下面的代码
        // _scrollController.animateTo(
        //   _scrollController.position.maxScrollExtent,
        //   duration: Duration(milliseconds: 300),
        //   curve: Curves.easeOut,
        // );
      }
    });
  }

  // 异步方法
  // 缓存方法
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('messages');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        messages = jsonList.map((json) => Msg.fromJson(json)).toList();
        _scrollToBottom();
      });
    }
  }

  // 保存数据到缓存
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((msg) => msg.toJson()).toList();
    prefs.setString('messages', json.encode(jsonList));
  }

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
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: SelectableText('小红同学')),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      ...messages.map(
                        (item) => MsgCard(
                          isUserType: item.isUser,
                          msg: item.msg,
                          image: item.image,
                          width: constraints.maxWidth,
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
                          child: Text('添加图片'),
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
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: constraints.maxHeight * 0.14,
                    width: constraints.maxWidth * 0.9,
                    child: TextField(
                      controller: inputController,
                      autofocus: true,
                      onSubmitted: (value) {
                        _handleSend();
                      },
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(40)),
                        ),
                        hint: SelectableText(
                          '和小红同学说点什么',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      widgets.add(const SizedBox(height: 12));
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
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  // 构建标题Widget
  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
        widgets.add(const SizedBox(height: 6));
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
            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
        children: items.map((item) {
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
            placeholder: (context, url) => const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => AspectRatio(
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

// 定义事件类型枚举
enum CozeEventType {
  conversationMessageDelta,
  conversationMessageCompleted,
  conversationChatCompleted,
  done,
  unknown,
}

// 消息数据模型
class CozeMessage {
  final String id;
  final String conversationId;
  final String botId;
  final String role;
  final String type;
  final String content;
  final String contentType;
  final String chatId;
  final String sectionId;
  final int? createdAt;
  final int? updatedAt;

  CozeMessage({
    required this.id,
    required this.conversationId,
    required this.botId,
    required this.role,
    required this.type,
    required this.content,
    required this.contentType,
    required this.chatId,
    required this.sectionId,
    this.createdAt,
    this.updatedAt,
  });

  factory CozeMessage.fromJson(Map<String, dynamic> json) {
    return CozeMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      botId: json['bot_id'] ?? '',
      role: json['role'] ?? '',
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      contentType: json['content_type'] ?? '',
      chatId: json['chat_id'] ?? '',
      sectionId: json['section_id'] ?? '',
      createdAt: json['created_at'] as int?,
      updatedAt: json['updated_at'] as int?,
    );
  }
}

// 聊天完成数据模型
class CozeChatCompleted {
  final String id;
  final String conversationId;
  final String botId;
  final int createdAt;
  final int completedAt;
  final Map<String, dynamic> lastError;
  final String status;
  final Map<String, dynamic> usage;
  final String sectionId;

  CozeChatCompleted({
    required this.id,
    required this.conversationId,
    required this.botId,
    required this.createdAt,
    required this.completedAt,
    required this.lastError,
    required this.status,
    required this.usage,
    required this.sectionId,
  });

  factory CozeChatCompleted.fromJson(Map<String, dynamic> json) {
    return CozeChatCompleted(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      botId: json['bot_id'] ?? '',
      createdAt: json['created_at'] ?? 0,
      completedAt: json['completed_at'] ?? 0,
      lastError: json['last_error'] ?? {},
      status: json['status'] ?? '',
      usage: json['usage'] ?? {},
      sectionId: json['section_id'] ?? '',
    );
  }
}

// 解析后的事件数据
class CozeStreamEvent {
  final CozeEventType type;
  final dynamic data;

  CozeStreamEvent({required this.type, this.data});
}

class CozeStreamService {
  final String apiUrl = 'https://api.coze.cn/v3/chat';
  final OAuthService _oAuthService;
  final String msg;

  // 用于保存当前事件类型，因为event和data是分开的行
  CozeEventType? _currentEventType;
  // 用于收集完整的回答内容
  String _fullAnswer = '';

  CozeStreamService({required this.msg, OAuthService? oauthService})
    : _oAuthService = oauthService ?? OAuthService();

  // 发送请求并返回事件流
  Stream<CozeStreamEvent> sendStreamRequest() async* {
    try {
      final token = await _oAuthService.getAccessToken();
      print('开始发送请求到: $apiUrl');
      final requestBody = jsonEncode({
        "bot_id": "7527187019618484259",
        "user_id": "123456789",
        "stream": true,
        "additional_messages": [
          {
            "content_type": "text",
            "role": "user",
            "type": "question",
            "content": msg,
          },
        ],
        "parameters": {},
      });

      final request = http.Request('POST', Uri.parse(apiUrl))
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Content-Type'] = 'application/json'
        ..body = requestBody;

      print('请求已发送，等待响应...');
      final response = await http.Client().send(request);

      print('收到响应，状态码: ${response.statusCode}');
      print('开始处理响应流...');

      // 按行解析流数据
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        print('收到数据块: ${chunk.length} 字符');

        // 分割每一行
        final lines = chunk.split('\n');
        print('数据块分割为 ${lines.length} 行');

        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isEmpty) {
            print('跳过空行');
            continue;
          }

          print('处理行: $trimmedLine');
          final event = _parseLine(trimmedLine);

          if (event != null) {
            print('解析到事件: ${event.type}');

            // 累积内容
            if (event.type == CozeEventType.conversationMessageDelta &&
                event.data is CozeMessage) {
              _fullAnswer += (event.data as CozeMessage).content;
              print('当前累积内容: $_fullAnswer');
            }

            yield event;
          } else {
            print('无法解析行: $trimmedLine');
          }
        }
      }

      print('响应流处理完成');
    } catch (e) {
      print('请求出错: $e');
      // 抛出错误，让订阅者知道
      throw e;
    }
  }

  // 解析单行数据
  CozeStreamEvent? _parseLine(String line) {
    try {
      // 处理事件行
      if (line.startsWith('event:')) {
        final eventTypeStr = line.substring(6).trim();
        _currentEventType = _parseEventType(eventTypeStr);
        // 事件行本身不产生事件，等待后续data行
        return null;
      }

      // 处理数据行
      if (line.startsWith('data:')) {
        if (_currentEventType == null) {
          print('收到data但没有对应的event，忽略此行');
          return null;
        }

        final dataStr = line.substring(5).trim();
        dynamic data;

        if (_currentEventType != CozeEventType.done) {
          try {
            final jsonData = jsonDecode(dataStr);

            // 根据事件类型解析不同的数据结构
            switch (_currentEventType!) {
              case CozeEventType.conversationMessageDelta:
              case CozeEventType.conversationMessageCompleted:
                data = CozeMessage.fromJson(jsonData);
                break;
              case CozeEventType.conversationChatCompleted:
                data = CozeChatCompleted.fromJson(jsonData);
                break;
              default:
                data = jsonData;
            }
          } catch (e) {
            print('解析data出错: $e, 原始数据: $dataStr');
            data = dataStr;
          }
        } else {
          data = dataStr;
        }

        // 创建事件并重置当前事件类型
        final event = CozeStreamEvent(type: _currentEventType!, data: data);
        _currentEventType = null;
        return event;
      }

      // 既不是event也不是data的行
      return null;
    } catch (e) {
      print('解析行出错: $e, 行内容: $line');
      return null;
    }
  }

  // 转换事件类型字符串为枚举
  CozeEventType _parseEventType(String eventTypeStr) {
    switch (eventTypeStr) {
      case 'conversation.message.delta':
        return CozeEventType.conversationMessageDelta;
      case 'conversation.message.completed':
        return CozeEventType.conversationMessageCompleted;
      case 'conversation.chat.completed':
        return CozeEventType.conversationChatCompleted;
      case 'done':
        return CozeEventType.done;
      default:
        return CozeEventType.unknown;
    }
  }

  // 获取完整的回答内容
  String get fullAnswer => _fullAnswer;
}

const String redirectUri = "http://localhost:3000/callback"; // 需与控制台配置一致
const String authorizationEndpoint =
    "https://www.coze.cn/api/permission/oauth2/authorize";
const String tokenEndpoint =
    "https://api.coze.cn/api/permission/oauth2/token"; // 一行代码带来的错误改了一晚上😭😭😭😭😭😭😭😭😭

class OAuthService {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  String? _codeVerifier;

  // 生成Code Verifier
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(16));
    return base64Url.encode(values).replaceAll('=', '');
  }

  // 生成Code Challenge
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // 启动PKCE流程获取token
  Future<String> getAccessToken() async {
    // 检查token是否有效
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    // 如果有refresh token尝试刷新
    if (_refreshToken != null) {
      try {
        final newToken = await _refreshAccessToken();
        return newToken;
      } catch (e) {
        print('刷新token失败，将重新获取: $e');
      }
    }

    // 完整PKCE流程
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);

    print('code_verifier: $_codeVerifier');
    print('code_challenge: $codeChallenge');
    // 构建授权URL
    final authorizationUrl = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': _generateCodeVerifier().substring(0, 16), // 简单的state生成
      },
    );
    print('即将打开的授权URL：${authorizationUrl.toString()}');

    // 启动本地服务器接收回调
    final codeCompleter = Completer<String>();
    final server = await _startCallbackServer(codeCompleter);

    // 打开浏览器让用户授权
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(
        authorizationUrl,
        // 根据平台选择合适的启动模式
        mode: LaunchMode.inAppBrowserView, // 打开系统浏览器（推荐授权场景）
      );
    } else {
      throw Exception('无法打开授权页面: ${authorizationUrl.toString()}');
    }

    // 等待获取授权code
    final code = await codeCompleter.future;
    await server.close();

    // 使用code交换token
    final tokenResponse = await _exchangeCodeForToken(code);
    _accessToken = tokenResponse['access_token'];
    _refreshToken = tokenResponse['refresh_token'];
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: tokenResponse['expires_in'] as int),
    );

    return _accessToken!;
  }

  // 启动本地回调服务器
  Future<HttpServer> _startCallbackServer(
    Completer<String> codeCompleter,
  ) async {
    // 使用函数声明替代闭包变量赋值
    Future<shelf.Response> handleCallbackRequest(shelf.Request request) async {
      final uri = request.requestedUri;
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        codeCompleter.completeError(Exception('授权失败: $error'));
        return shelf.Response.ok('授权失败，请关闭页面返回应用');
      }

      if (code != null) {
        codeCompleter.complete(code);
        return shelf.Response.ok(
          '<html><body>授权成功，请关闭页面返回应用</body></html>', // 使用 HTML 格式
          headers: {'Content-Type': 'text/html; charset=utf-8'}, // 明确指定类型
        );
      }

      codeCompleter.completeError(Exception('未获取到授权code'));
      return shelf.Response.ok('授权失败，请关闭页面返回应用');
    }

    // shelf_io.serve 返回的是 Future<HttpServer>（来自 dart:io）
    final server = await io.serve(handleCallbackRequest, 'localhost', 3000);
    print('本地回调服务器启动在: http://${server.address.host}:${server.port}');
    return server; // server 的类型是 HttpServer，与返回类型匹配
  }

  // 用授权code交换token
  Future<Map<String, dynamic>> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_verifier': _codeVerifier,
      }),
    );
    // 打印关键调试信息
    if (response.request is http.Request) {
      final requestBody = (response.request as http.Request).body;
      print('Token 交换请求参数: $requestBody');
    } else {
      print('Token 交换请求参数: 无法获取（非 Request 类型）');
    }
    print('Token 交换响应状态码: ${response.statusCode}'); // 打印状态码
    print('Token 交换响应原始内容: ${response.body}'); // 打印原始响应（可能包含错误信息）

    if (response.statusCode != 200) {
      throw Exception('交换token失败: ${response.body}');
    }

    return json.decode(response.body);
  }

  // 刷新token
  Future<String> _refreshAccessToken() async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
        'client_id': clientId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('刷新token失败: ${response.body}');
    }

    final tokenResponse = json.decode(response.body);
    _accessToken = tokenResponse['access_token'];
    _refreshToken = tokenResponse['refresh_token'];
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: tokenResponse['expires_in'] as int),
    );

    return _accessToken!;
  }
}
