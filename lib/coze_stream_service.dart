import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:red_helper/o_auth_service.dart';

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
