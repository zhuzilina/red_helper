import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/global_oauth_manager.dart';

/// OAuth刷新token使用示例
/// 展示如何在API服务中正确处理token刷新
class OAuthRefreshExample {
  final GlobalOAuthManager _oAuthManager;

  OAuthRefreshExample() : _oAuthManager = GlobalOAuthManager();

  /// 调用需要OAuth认证的API（自动处理token刷新）
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
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API调用失败 [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      throw Exception('API调用异常: $e');
    }
  }

  /// 手动刷新token的示例
  Future<String> manuallyRefreshToken() async {
    try {
      print("🔄 手动刷新OAuth Access Token...");
      final newToken = await _oAuthManager.refreshToken();
      print("✅ 手动刷新成功");
      return newToken;
    } catch (e) {
      print("❌ 手动刷新失败: $e");
      throw e;
    }
  }

  /// 检查token状态的示例
  void checkTokenStatus() {
    final status = _oAuthManager.getTokenStatus();
    print("📊 当前Token状态:");
    print("  - 有访问令牌: ${status['hasAccessToken']}");
    print("  - 有刷新令牌: ${status['hasRefreshToken']}");
    print("  - 令牌有效: ${status['isValid']}");
    print("  - 剩余秒数: ${status['timeUntilExpiry']}");
    print("  - 正在刷新: ${status['isRefreshing']}");
  }

  /// 清除token缓存的示例（用于调试）
  Future<void> clearTokenCache() async {
    try {
      await _oAuthManager.clearTokenCache();
      print("🗑️ Token缓存已清除");
    } catch (e) {
      print("❌ 清除缓存失败: $e");
    }
  }

  /// 完整的API调用流程示例
  Future<void> completeApiFlowExample() async {
    try {
      print("🚀 开始完整的API调用流程示例...");

      // 1. 检查初始状态
      print("\n📊 步骤1: 检查初始Token状态");
      checkTokenStatus();

      // 2. 调用API（会自动处理token获取和刷新）
      print("\n📞 步骤2: 调用需要认证的API");
      final result = await callAuthenticatedApi(
        url: 'https://api.coze.cn/v3/chat',
        body: {
          'message': 'Hello, this is a test message',
          'bot_id': 'your_bot_id',
        },
      );
      print("✅ API调用成功: ${result.toString().substring(0, 100)}...");

      // 3. 再次检查状态
      print("\n📊 步骤3: 检查API调用后的Token状态");
      checkTokenStatus();

      // 4. 手动刷新token（可选）
      print("\n🔄 步骤4: 手动刷新Token（演示用）");
      try {
        final newToken = await manuallyRefreshToken();
        print("✅ 手动刷新成功，新Token长度: ${newToken.length}");
      } catch (e) {
        print("⚠️ 手动刷新失败（可能是正常的）: $e");
      }

      // 5. 最终状态检查
      print("\n📊 步骤5: 最终Token状态");
      checkTokenStatus();

      print("\n🎉 完整API调用流程示例完成！");
    } catch (e) {
      print("❌ API调用流程示例失败: $e");
    }
  }
}

/// 使用示例
void main() async {
  final example = OAuthRefreshExample();
  await example.completeApiFlowExample();
}


