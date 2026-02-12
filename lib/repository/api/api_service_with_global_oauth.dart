import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/global_oauth_manager.dart';

/// 使用全局OAuth管理器的API服务示例
class ApiServiceWithGlobalOAuth {
  final GlobalOAuthManager _oAuthManager;

  ApiServiceWithGlobalOAuth() : _oAuthManager = GlobalOAuthManager();

  /// 调用需要OAuth认证的API
  Future<Map<String, dynamic>> callAuthenticatedApi({
    required String url,
    required Map<String, dynamic> body,
    String method = 'POST',
  }) async {
    try {
      // 获取访问令牌（会自动处理刷新）
      final accessToken = await _oAuthManager.getAccessToken();

      // 构建请求
      final uri = Uri.parse(url);
      final request = http.Request(method, uri)
        ..headers.addAll({
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        })
        ..body = jsonEncode(body);

      // 发送请求
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('API请求失败: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print("❌ API调用失败: $e");
      rethrow;
    }
  }

  /// 调用Coze Workflow API
  Future<Map<String, dynamic>> callCozeWorkflow({
    required String workflowId,
    required Map<String, dynamic> parameters,
  }) async {
    return await callAuthenticatedApi(
      url: 'https://api.coze.cn/v1/workflow/run',
      body: {'workflow_id': workflowId, 'parameters': parameters},
    );
  }

  /// 调用Coze Chat API
  Future<Map<String, dynamic>> callCozeChat({
    required String botId,
    required String message,
    String userId = '123456789',
  }) async {
    return await callAuthenticatedApi(
      url: 'https://api.coze.cn/v3/chat',
      body: {
        'bot_id': botId,
        'user_id': userId,
        'stream': false,
        'additional_messages': [
          {
            'content_type': 'text',
            'role': 'user',
            'type': 'question',
            'content': message,
          },
        ],
        'parameters': {},
      },
    );
  }

  /// 获取当前OAuth状态
  Map<String, dynamic> getOAuthStatus() {
    return _oAuthManager.getTokenStatus();
  }

  /// 清除OAuth缓存（用于调试）
  Future<void> clearOAuthCache() async {
    await _oAuthManager.clearTokenCache();
  }
}


