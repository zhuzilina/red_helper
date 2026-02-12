import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 添加时间格式化依赖

class Message {
  final String id;
  final String sender;
  final String avatar;
  String lastMessage;
  final DateTime time;
  int unread;

  Message({
    required this.id,
    required this.sender,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });
}

class MessagePage extends StatefulWidget {
  final dynamic arguments;
  const MessagePage({super.key, required this.arguments});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<Message> messages = [
    Message(
      id: '1',
      sender: '张三',
      avatar: 'https://example.com/avatar1.png',
      lastMessage: '你好，今天有空吗？',
      time: DateTime.now().subtract(Duration(minutes: 15)),
      unread: 2,
    ),
    Message(
      id: '2',
      sender: '李四',
      avatar: 'https://example.com/avatar2.png',
      lastMessage: '会议改到下午3点',
      time: DateTime.now().subtract(Duration(hours: 2)),
      unread: 0,
    ),
  ];

  // 处理消息点击
  void _handleMessageTap(Message message) {
    setState(() {
      message.unread = 0; // 清除未读
    });
    _navigateToChat(message);
  }

  // 添加新消息
  void _addNewMessage() {
    setState(() {
      messages.insert(
        0,
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: '新联系人',
          avatar: 'https://example.com/new_avatar.png',
          lastMessage: '这是第一条消息',
          time: DateTime.now(),
          unread: 1,
        ),
      );
    });
  }

  // 删除消息
  void _deleteMessage(int index) {
    final deletedMessage = messages[index];
    setState(() {
      messages.removeAt(index);
    });

    // 显示撤销操作
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 ${deletedMessage.sender} 的对话'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() {
              messages.insert(index, deletedMessage);
            });
          },
        ),
      ),
    );
  }

  void _navigateToChat(Message message) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(message: message)),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time); // 使用更友好的时间格式
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('消息列表（${messages.where((m) => m.unread > 0).length} 未读）'),
        actions: [IconButton(icon: Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Dismissible(
            key: Key(message.id),
            background: Container(color: Colors.red),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text("确认删除"),
                      content: Text("确定要删除与 ${message.sender} 的对话吗？"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("取消"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            "删除",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
            },
            onDismissed: (direction) => _deleteMessage(index),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(message.avatar),
                radius: 25,
              ),
              title: Text(
                message.sender,
                style: TextStyle(
                  fontWeight:
                      message.unread > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                message.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: message.unread > 0 ? Colors.black : Colors.grey,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(message.time),
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (message.unread > 0)
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${message.unread}',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              onTap: () => _handleMessageTap(message),
              onLongPress: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text("操作选项"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(Icons.mark_chat_read),
                              title: Text("标记为已读"),
                              onTap: () {
                                setState(() {
                                  message.unread = 0;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.delete),
                              title: Text("删除对话"),
                              onTap: () {
                                _deleteMessage(index);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMessage,
        child: Icon(Icons.message),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final Message message;

  const ChatPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(message.sender)),
      body: Center(child: Text('与 ${message.sender} 的聊天页面')),
    );
  }
}
