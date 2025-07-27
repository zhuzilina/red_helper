import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:red_helper/cognitive_switch_widget.dart';
import 'package:red_helper/coze_stream_service.dart';
import 'package:red_helper/loading_animation.dart';
import 'package:red_helper/msg_card.dart';
import 'package:red_helper/providers/msg_state.dart';
import 'package:red_helper/repository/models/msg.dart';
import 'package:http/http.dart' as http;

class CozePage extends StatefulWidget {
  const CozePage({super.key, required this.callMsg, this.autoFocus = true});
  final String callMsg;
  final bool autoFocus;
  @override
  State<StatefulWidget> createState() {
    return _CozePage();
  }
}

class _CozePage extends State<CozePage> {
  late final appState;
  // 控制器
  final TextEditingController inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  // 信号量
  bool isLoading = true;
  bool isSend = false;
  bool isDeep = false;
  bool _isSpeaking = false;
  List<Msg> messages = [];
  // 值-消息文本
  Msg? msg;
  String? lastMsg;
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
          lastMsg = service.fullAnswer;
          // 最终状态更新
          setState(() {
            isLoading = false;
            isSend = false;
            _speak();
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
        appState.saveMessages();
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
      }
    });
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

  // 语音合成
  Future<void> _initTTS() async {
    // ... 其他设置（语言、语速等）
    await _flutterTts.setLanguage("zh-CN");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    // 当朗读完成时触发
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false; // 朗读完成后更新状态为未朗读
      });
    });

    // 添加错误处理回调
    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // 朗读文本
  Future<void> _speak() async {
    if (lastMsg != null && lastMsg!.isNotEmpty) {
      setState(() {
        _isSpeaking = true;
      });
      await _flutterTts.speak(lastMsg!);
    }
  }

  // 停止朗读
  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  // Future<Map<String, dynamic>> sendMessage(String msg, String? fileId) async {
  //   var url = Uri.parse('http://121.36.87.174:3000/?msg=$msg');
  //   if (fileId != null) {
  //     url = Uri.parse('http://121.36.87.174:3000/?msg=$msg&file_id=$fileId');
  //   }
  //   try {
  //     print('开始发送');
  //     var response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       var jsonResponse = jsonDecode(response.body);
  //       return jsonResponse;
  //     } else {
  //       throw ('请求失败:${response.body}');
  //     }
  //   } catch (e) {
  //     throw ("发生了错误:$e");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    inputController.text = widget.callMsg;
    _initTTS();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appState = Provider.of<MsgState>(context);
    messages = appState.messages;
    _scrollToBottom();
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
                      ? GestureDetector(
                          onTap: () {
                            _handleAddPicture();
                          },
                          child: Card(
                            // 根据状态改变卡片样式
                            color: Theme.of(context).colorScheme.surface,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 28,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                  ),
                                  Text(
                                    '添加图片',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

                  CognitiveSwitchWidget(),
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
                      autofocus: widget.autoFocus,
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

class QuickStart extends StatefulWidget {
  const QuickStart({super.key, required this.callMsg, required this.callback});
  final String callMsg;
  final Function() callback;

  @override
  State<StatefulWidget> createState() => _QuickStart();
}

class _QuickStart extends State<QuickStart> {
  final int standLen = 600;
  String loadingLabel = '加载中';
  // 信号量
  bool isLoading = true;
  bool isSend = false;
  bool isOk = false;
  // 值-消息文本
  Msg? msg;
  // 保存Stream订阅，防止泄漏
  StreamSubscription? _streamSubscription;
  // 标记是否已经处理过，防止重复执行
  bool _hasProcessed = false;

  Future<bool> _handleSend() async {
    final message = widget.callMsg;
    if (message.isEmpty) return isOk;

    // 创建发送信号控制状态
    setState(() {
      isLoading = true;
      isSend = true;
    });

    final service = CozeStreamService(msg: message);
    print('创建流订阅...');

    // 取消之前的订阅（如果存在）
    if (_streamSubscription != null) {
      await _streamSubscription!.cancel();
    }

    _streamSubscription = service.sendStreamRequest().listen((event) {
      print('收到事件: ${event.type}');
      final currentLen = service.fullAnswer.length;
      if (currentLen > 50) {
        setState(() {
          loadingLabel =
              '${((currentLen / standLen) * 100 >= 100 ? 100 : (currentLen / standLen) * 100).toStringAsFixed(1)}%';
        });
      }
    });

    _streamSubscription!.onDone(() async {
      if (!mounted) return;

      final Msg botMsg = Msg(isUser: false, msg: service.fullAnswer);
      final Msg userMsg = Msg(isUser: true, msg: widget.callMsg);

      bool ok = false;
      setState(() {
        isLoading = false;
        ok = Provider.of<MsgState>(
          context,
          listen: false,
        ).addMessage(botMsg, userMsg);
      });

      // 立即检查mounted，避免setState后销毁
      if (!mounted) return;

      if (ok) {
        _pushPage(); // 现在导航在安全上下文中
      }
    });

    _streamSubscription!.onError((error) {
      print('发生错误: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          isSend = false;
        });
      }
      _streamSubscription?.cancel();
    });

    return isOk;
  }

  void quickStart() async {
    if (widget.callMsg.isNotEmpty && !_hasProcessed) {
      _hasProcessed = true; // 标记为已处理，防止重复执行
      await _handleSend();
    }
  }

  void _pushPage() async {
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => CozePage(callMsg: '', autoFocus: false),
      ),
    );
    widget.callback();
  }

  @override
  void initState() {
    super.initState();
    // 改用initState初始化，避免didChangeDependencies的频繁调用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      quickStart();
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingAnimation(
      isLoading: isLoading && isSend,
      loadingText: loadingLabel,
    );
  }
}
