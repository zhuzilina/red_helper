# OAuth刷新Token实现文档

## 概述

根据OAuth PKCE文档，我们实现了标准的"刷新 OAuth Access Token"功能，当token失效时只需要访问刷新token的API获取新token，而不需要重新进行完整的授权流程。

## 实现特性

### ✅ 核心功能
- **自动刷新**: 当access_token过期时自动使用refresh_token刷新
- **手动刷新**: 提供公共方法供外部手动刷新token
- **错误处理**: 正确处理refresh_token过期的情况
- **状态监控**: 提供详细的token状态信息
- **并发安全**: 多个请求同时等待token刷新时，只进行一次刷新操作

### 🔄 刷新流程

1. **检查token有效性**: 验证当前access_token是否有效
2. **自动刷新**: 如果token过期且有refresh_token，自动调用刷新API
3. **错误恢复**: 如果refresh_token也过期，清除缓存并重新授权
4. **并发处理**: 多个请求共享同一个刷新操作

## API实现

### 刷新Token API

根据OAuth文档，刷新token的API实现如下：

```dart
/// 刷新令牌
/// 根据OAuth文档实现标准的刷新token API
Future<String> _refreshAccessToken() async {
  if (_refreshToken == null) {
    throw Exception('没有可用的refresh_token');
  }

  final response = await http.post(
    Uri.parse(tokenEndpoint),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: json.encode({
      'grant_type': 'refresh_token',
      'refresh_token': _refreshToken,
      'client_id': clientId,
    }),
  );

  if (response.statusCode == 200) {
    final tokenResponse = json.decode(response.body);
    
    // 更新token信息
    _accessToken = tokenResponse['access_token'];
    _refreshToken = tokenResponse['refresh_token']; // 新的refresh_token
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: tokenResponse['expires_in'] as int),
    );
    
    await _saveTokenToStorage();
    return _accessToken!;
  } else {
    // 处理错误情况
    final errorResponse = json.decode(response.body);
    final error = errorResponse['error'] ?? 'unknown_error';
    final errorDescription = errorResponse['error_description'] ?? '未知错误';
    
    // 如果是refresh_token过期，清除本地存储
    if (error == 'invalid_grant' || error == 'invalid_token') {
      await _clearTokenStorage();
    }
    
    throw Exception('刷新OAuth Access Token失败 [$error]: $errorDescription');
  }
}
```

### 公共刷新方法

```dart
/// 强制刷新token（公共方法）
/// 外部可以直接调用此方法来刷新token
Future<String> refreshToken() async {
  if (_refreshToken == null) {
    throw Exception('没有可用的refresh_token，需要重新授权');
  }

  return await _refreshAccessToken();
}
```

## 使用方式

### 1. 自动刷新（推荐）

```dart
final oAuthManager = GlobalOAuthManager();

// 获取访问令牌（会自动处理刷新）
final token = await oAuthManager.getAccessToken();
```

### 2. 手动刷新

```dart
final oAuthManager = GlobalOAuthManager();

// 手动刷新token
try {
  final newToken = await oAuthManager.refreshToken();
  print('Token刷新成功');
} catch (e) {
  print('Token刷新失败: $e');
}
```

### 3. 状态监控

```dart
final oAuthManager = GlobalOAuthManager();

// 获取token状态
final status = oAuthManager.getTokenStatus();
print('Token状态: $status');
```

## 错误处理

### 常见错误类型

1. **invalid_grant**: refresh_token已过期或无效
2. **invalid_token**: refresh_token格式错误
3. **unauthorized_client**: 客户端ID无效
4. **unsupported_grant_type**: 不支持的授权类型

### 错误恢复策略

- **refresh_token过期**: 清除本地存储，重新进行完整授权
- **网络错误**: 重试机制
- **服务器错误**: 适当的错误提示

## 状态监控

### Token状态信息

```dart
Map<String, dynamic> getTokenStatus() {
  return {
    'hasAccessToken': _accessToken != null,
    'hasRefreshToken': _refreshToken != null,
    'isValid': _isTokenValid(),
    'expiry': _tokenExpiry?.toIso8601String(),
    'timeUntilExpiry': timeUntilExpiry, // 剩余秒数
    'isRefreshing': _isRefreshing,
    'pendingRequests': _pendingRequests.length,
    'accessTokenLength': _accessToken?.length ?? 0,
    'refreshTokenLength': _refreshToken?.length ?? 0,
  };
}
```

## 测试

### 测试文件

- `test_oauth_refresh_token.dart`: 测试刷新token功能
- `lib/repository/api/oauth_refresh_example.dart`: 使用示例

### 运行测试

```bash
flutter run test_oauth_refresh_token.dart
```

## 优势

### 用户体验
- ✅ 减少频繁的浏览器授权弹窗
- ✅ 提高应用响应速度
- ✅ 无缝的token刷新体验

### 技术优势
- ✅ 符合OAuth 2.0标准
- ✅ 自动错误恢复
- ✅ 并发安全
- ✅ 详细的状态监控
- ✅ 易于调试和维护

## 注意事项

1. **refresh_token有效期**: 30天，过期后需要重新授权
2. **并发请求**: 多个请求同时等待token刷新时，共享同一个刷新操作
3. **错误处理**: 正确处理refresh_token过期的情况
4. **安全考虑**: refresh_token存储在本地，需要适当的安全措施

## 总结

通过实现标准的OAuth刷新token功能，我们实现了：

- 🔄 **自动刷新**: token过期时自动刷新，无需用户交互
- 🛡️ **错误恢复**: 自动处理refresh_token过期的情况
- 📊 **状态监控**: 提供详细的token状态信息
- 🔧 **易于使用**: 简单的API接口，易于集成

这大大改善了用户体验，减少了频繁的授权流程，提高了应用的稳定性和响应速度。


