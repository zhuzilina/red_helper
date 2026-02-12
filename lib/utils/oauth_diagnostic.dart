import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'global_oauth_manager.dart';
import '../env.dart';

/// OAuth诊断工具
/// 用于调试OAuth token和API调用问题
class OAuthDiagnostic {
  final GlobalOAuthManager _oAuthManager;

  OAuthDiagnostic() : _oAuthManager = GlobalOAuthManager();

  /// 运行完整的诊断
  Future<void> runDiagnostic() async {
    print("🔍 开始OAuth诊断...");

    try {
      // 1. 检查配置
      await _checkConfiguration();

      // 2. 检查OAuth管理器状态
      await _checkOAuthManagerStatus();

      // 3. 获取token
      final token = await _getAndValidateToken();

      // 4. 测试API调用
      await _testApiCalls(token);

      // 5. 检查权限
      await _checkPermissions(token);

      print("\n🎉 OAuth诊断完成！");
    } catch (e) {
      print("❌ 诊断失败: $e");
    }
  }

  /// 检查配置
  Future<void> _checkConfiguration() async {
    print("\n📋 步骤1: 检查配置");
    print("  - Client ID: $clientId");
    print("  - Question Client ID: $questionClientId");
    print("  - Workflow ID: $workflowId");
    print("  - Question Bot ID: $questionBotId");
    print("  - API Token: ${apiToken.substring(0, 20)}...");

    if (clientId.isEmpty) {
      throw Exception("Client ID 未配置");
    }
    if (workflowId.isEmpty) {
      throw Exception("Workflow ID 未配置");
    }

    print("✅ 配置检查通过");
  }

  /// 检查OAuth管理器状态
  Future<void> _checkOAuthManagerStatus() async {
    print("\n📊 步骤2: 检查OAuth管理器状态");

    await _oAuthManager.initialize();
    final status = _oAuthManager.getTokenStatus();

    print("  - 有访问令牌: ${status['hasAccessToken']}");
    print("  - 有刷新令牌: ${status['hasRefreshToken']}");
    print("  - 令牌有效: ${status['isValid']}");
    print("  - 剩余秒数: ${status['timeUntilExpiry']}");
    print("  - 正在刷新: ${status['isRefreshing']}");
    print("  - 等待请求数: ${status['pendingRequests']}");
    print("  - 访问令牌长度: ${status['accessTokenLength']}");
    print("  - 刷新令牌长度: ${status['refreshTokenLength']}");

    print("✅ OAuth管理器状态检查完成");
  }

  /// 获取并验证token
  Future<String> _getAndValidateToken() async {
    print("\n🔑 步骤3: 获取并验证Token");

    final token = await _oAuthManager.getAccessToken();
    print("✅ Token获取成功");
    print("  - Token长度: ${token.length} 字符");
    print(
      "  - Token预览: ${token.substring(0, token.length > 30 ? 30 : token.length)}...",
    );

    // 验证token格式
    if (!token.startsWith('czu_')) {
      print("⚠️ Token格式可能不正确，应该以 'czu_' 开头");
    } else {
      print("✅ Token格式正确");
    }

    return token;
  }

  /// 测试API调用
  Future<void> _testApiCalls(String token) async {
    print("\n🌐 步骤4: 测试API调用");

    // 测试不同的API端点
    final endpoints = [
      {
        'name': 'Workflow API',
        'url': 'https://api.coze.cn/v1/workflow/run',
        'body': {
          "workflow_id": workflowId,
          "parameters": {"input": "test"},
        },
      },
      {
        'name': 'Chat API',
        'url': 'https://api.coze.cn/v3/chat',
        'body': {
          "bot_id": questionBotId,
          "messages": [
            {"role": "user", "content": "test"},
          ],
        },
      },
      {
        'name': 'Bot List API',
        'url': 'https://api.coze.cn/v1/bot/list',
        'body': {},
      },
    ];

    for (final endpoint in endpoints) {
      await _testEndpoint(
        token,
        endpoint['name'] as String,
        endpoint['url'] as String,
        endpoint['body'] as Map<String, dynamic>,
      );
    }
  }

  /// 测试单个API端点
  Future<void> _testEndpoint(
    String token,
    String name,
    String url,
    Map<String, dynamic> body,
  ) async {
    print("\n🔍 测试 $name: $url");

    try {
      final uri = Uri.parse(url);
      final request = http.Request("POST", uri)
        ..headers.addAll({
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Flutter/1.0",
          "Accept": "application/json",
        })
        ..body = jsonEncode(body);

      print("📤 发送请求...");
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📥 响应状态码: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ $name 调用成功！");
        print(
          "📄 响应预览: ${responseBody.substring(0, responseBody.length > 100 ? 100 : responseBody.length)}...",
        );
      } else if (response.statusCode == 401) {
        print("❌ $name 返回401 - Token无效");
        print("📄 错误详情: $responseBody");
      } else if (response.statusCode == 403) {
        print("⚠️ $name 返回403 - 权限不足");
        print("📄 错误详情: $responseBody");
      } else {
        print("⚠️ $name 返回${response.statusCode} - 其他错误");
        print("📄 错误详情: $responseBody");
      }
    } catch (e) {
      print("❌ $name 请求异常: $e");
    }
  }

  /// 检查权限
  Future<void> _checkPermissions(String token) async {
    print("\n🔐 步骤5: 检查权限");

    try {
      // 尝试获取用户信息或权限信息
      final uri = Uri.parse('https://api.coze.cn/v1/user/info');
      final request = http.Request("GET", uri)
        ..headers.addAll({
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📥 用户信息API响应: ${response.statusCode}");
      if (response.statusCode == 200) {
        print("✅ 用户信息获取成功");
        print(
          "📄 用户信息: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...",
        );
      } else {
        print("⚠️ 用户信息获取失败: $responseBody");
      }
    } catch (e) {
      print("❌ 权限检查失败: $e");
    }
  }

  /// 清除token缓存并重新测试
  Future<void> clearCacheAndRetest() async {
    print("\n🔄 清除缓存并重新测试...");

    await _oAuthManager.clearTokenCache();
    print("✅ Token缓存已清除");

    await runDiagnostic();
  }
}

/// 使用示例
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final diagnostic = OAuthDiagnostic();
  await diagnostic.runDiagnostic();
}
