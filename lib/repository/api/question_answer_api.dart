import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../env.dart';
import '../../utils/global_oauth_manager.dart';

class QuestionAnswerService {
  final GlobalOAuthManager _oAuthManager;

  QuestionAnswerService(this._oAuthManager);

  /// 调用问题解答API
  Future<QuestionAnswerResponse> getAnswer(String question) async {
    try {
      print("🚀 开始调用问题解答API");
      print("📝 问题: $question");

      // 获取访问令牌
      await _oAuthManager.initialize();
      final accessToken = await _oAuthManager.getAccessToken();
      print("✅ 获取访问令牌成功");

      // 构建请求URL
      final uri = Uri.parse('https://api.coze.cn/v3/chat');

      // 构建请求体
      final requestBody = {
        "bot_id": questionBotId,
        "user_id": "123456789",
        "stream": true,
        "additional_messages": [
          {
            "content_type": "text",
            "role": "user",
            "type": "question",
            "content": question,
          },
        ],
        "parameters": {},
      };

      print("📤 发送请求到: $uri");
      print("📋 请求体: ${jsonEncode(requestBody)}");

      // 发送请求
      final request = http.Request("POST", uri)
        ..headers.addAll({
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        })
        ..body = jsonEncode(requestBody);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print("⏰ API请求超时");
          throw TimeoutException('API请求超时', const Duration(seconds: 60));
        },
      );

      print("📥 收到响应，状态码: ${streamedResponse.statusCode}");

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print("❌ API请求失败: ${streamedResponse.statusCode} - $errorBody");
        throw Exception('API请求失败: ${streamedResponse.statusCode}');
      }

      // 处理流式响应
      return await _processStreamResponse(streamedResponse.stream);
    } catch (e) {
      print("❌ 调用问题解答API失败: $e");
      throw Exception('调用问题解答API失败: $e');
    }
  }

  /// 处理流式响应
  Future<QuestionAnswerResponse> _processStreamResponse(
    Stream<List<int>> stream,
  ) async {
    final response = QuestionAnswerResponse();
    final processedDataIds = <String>{}; // 用于防止重复处理

    try {
      await stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
            print("📄 收到行: $line");

            if (line.startsWith("event:")) {
              final event = line.substring(6).trim();
              print("🔍 事件类型: $event");

              if (event == "conversation.chat.completed") {
                response.isCompleted = true;
              }
            } else if (line.startsWith("data:")) {
              final data = line.substring(5).trim();
              if (data != "[DONE]" && data.isNotEmpty) {
                try {
                  final jsonData = jsonDecode(data);

                  // 生成数据ID用于去重
                  final dataId = _generateDataId(jsonData);
                  if (processedDataIds.contains(dataId)) {
                    print("⚠️ 跳过重复数据: $dataId");
                    return;
                  }
                  processedDataIds.add(dataId);

                  _processDataEvent(jsonData, response);
                } catch (e) {
                  print("⚠️ 解析数据失败: $e");
                }
              }
            }
          });

      print("✅ 流式响应处理完成，处理了 ${processedDataIds.length} 个数据块");
      return response;
    } catch (e) {
      print("❌ 处理流式响应失败: $e");
      throw Exception('处理流式响应失败: $e');
    }
  }

  /// 生成数据ID用于去重
  String _generateDataId(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final contentType = data['content_type'] ?? '';
    final content = data['content'] ?? '';

    // 基于类型和内容生成唯一ID
    return '${type}_${contentType}_${content.hashCode}';
  }

  /// 处理数据事件
  void _processDataEvent(
    Map<String, dynamic> data,
    QuestionAnswerResponse response,
  ) {
    final type = data['type'] ?? '';
    final contentType = data['content_type'] ?? '';
    final content = data['content'] as String?;

    print("🔍 处理数据事件 - 类型: $type, 内容类型: $contentType");

    if (type == 'answer') {
      if (content != null && content.isNotEmpty) {
        final beforeLength = response.answer.length;
        response.answer += content;
        final afterLength = response.answer.length;
        print("📝 累积答案: $beforeLength -> $afterLength 字符");
        print(
          "📄 新增内容: ${content.substring(0, content.length > 50 ? 50 : content.length)}...",
        );
      }
    } else if (type == 'follow_up') {
      // 处理问题建议
      if (content != null && content.isNotEmpty) {
        // 检查是否已存在相同建议
        if (!response.suggestions.contains(content)) {
          response.suggestions.add(content);
          print(
            "💡 添加建议: ${content.substring(0, content.length > 50 ? 50 : content.length)}...",
          );
        } else {
          print(
            "⚠️ 跳过重复建议: ${content.substring(0, content.length > 50 ? 50 : content.length)}...",
          );
        }
      }
    } else if (contentType == 'object_string') {
      // 处理多模态内容（包含图片等）
      try {
        if (content != null && content.isNotEmpty) {
          final objectString = jsonDecode(content) as List;
          for (final obj in objectString) {
            if (obj['type'] == 'image' && obj['file_url'] != null) {
              final imageUrl = obj['file_url'];
              // 检查是否已存在相同图片
              if (!response.images.contains(imageUrl)) {
                response.images.add(imageUrl);
                print("🖼️ 添加图片: $imageUrl");
              } else {
                print("⚠️ 跳过重复图片: $imageUrl");
              }
            }
          }
        }
      } catch (e) {
        print("⚠️ 解析多模态内容失败: $e");
      }
    } else {
      print("⚠️ 未知数据类型: $type, 内容类型: $contentType");
    }
  }
}

/// 问题解答响应数据类
class QuestionAnswerResponse {
  String answer = '';
  List<String> suggestions = [];
  List<String> images = [];
  bool isCompleted = false;

  QuestionAnswerResponse();

  bool get hasContent =>
      answer.isNotEmpty || suggestions.isNotEmpty || images.isNotEmpty;

  @override
  String toString() {
    return 'QuestionAnswerResponse{answer: ${answer.length}字符, suggestions: ${suggestions.length}个, images: ${images.length}个, isCompleted: $isCompleted}';
  }
}
