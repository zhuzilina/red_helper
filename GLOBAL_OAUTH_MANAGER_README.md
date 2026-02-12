# 全局OAuth管理器使用指南

## 概述

全局OAuth管理器 (`GlobalOAuthManager`) 是一个单例模式的OAuth token管理器，确保整个应用使用同一个token实例，并提供自动刷新功能。

## 主要特性

- ✅ **单例模式**: 整个应用使用同一个token实例
- ✅ **自动刷新**: 当token过期时自动刷新，无需手动处理
- ✅ **并发安全**: 多个请求同时等待token刷新时，只进行一次刷新操作
- ✅ **持久化存储**: token自动保存到本地存储
- ✅ **状态监控**: 提供token状态查询功能

## 使用方法

### 1. 初始化

在应用启动时初始化（已在 `main.dart` 中配置）：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化全局OAuth管理器
  final oAuthManager = GlobalOAuthManager();
  await oAuthManager.initialize();
  
  // ... 其他初始化代码
}
```

### 2. 在服务中使用

#### 方式一：直接使用全局管理器

```dart
import 'package:red_helper/utils/global_oauth_manager.dart';

class MyService {
  final GlobalOAuthManager _oAuthManager = GlobalOAuthManager();
  
  Future<void> callApi() async {
    try {
      // 获取访问令牌（会自动处理刷新）
      final token = await _oAuthManager.getAccessToken();
      
      // 使用token调用API
      // ...
    } catch (e) {
      print('API调用失败: $e');
    }
  }
}
```

#### 方式二：通过构造函数注入

```dart
class MyService {
  final GlobalOAuthManager _oAuthManager;
  
  MyService(this._oAuthManager);
  
  Future<void> callApi() async {
    final token = await _oAuthManager.getAccessToken();
    // ...
  }
}

// 使用时
final service = MyService(GlobalOAuthManager());
```

### 3. 已修改的文件

以下文件已经修改为使用全局OAuth管理器：

1. **`lib/pages/content_page/super_page/generate.dart`**
   - 移除了本地OAuthService实例
   - 使用全局OAuth管理器获取token

2. **`lib/pages/coze_page/coze_stream_service.dart`**
   - 构造函数参数改为GlobalOAuthManager
   - 使用全局管理器处理token获取

3. **`lib/repository/api/question_answer_api.dart`**
   - 构造函数参数改为GlobalOAuthManager
   - 使用全局管理器处理token获取

4. **`lib/main.dart`**
   - 在应用启动时初始化全局OAuth管理器

## API参考

### GlobalOAuthManager

#### 方法

- `Future<void> initialize()`: 初始化管理器，从本地存储加载token
- `Future<String> getAccessToken()`: 获取访问令牌（自动处理刷新）
- `Future<void> clearTokenCache()`: 清除token缓存
- `Map<String, dynamic> getTokenStatus()`: 获取当前token状态

#### Token状态信息

```dart
{
  'hasAccessToken': bool,      // 是否有访问令牌
  'hasRefreshToken': bool,     // 是否有刷新令牌
  'isValid': bool,            // 令牌是否有效
  'expiry': String?,          // 过期时间
  'isRefreshing': bool,       // 是否正在刷新
  'pendingRequests': int,     // 等待中的请求数量
}
```

## 工作流程

1. **首次使用**: 如果没有token，会启动完整的OAuth授权流程
2. **Token有效**: 直接返回缓存的token
3. **Token过期**: 自动使用refresh_token刷新
4. **刷新失败**: 清除缓存，重新进行完整授权
5. **并发请求**: 多个请求同时等待token刷新时，只进行一次刷新操作

## 错误处理

- **网络错误**: 抛出网络异常
- **授权失败**: 抛出授权异常
- **刷新失败**: 自动尝试重新授权
- **API错误**: 根据错误类型处理（401等）

## 调试功能

### 查看Token状态

```dart
final oAuthManager = GlobalOAuthManager();
final status = oAuthManager.getTokenStatus();
print('Token状态: $status');
```

### 清除Token缓存

```dart
final oAuthManager = GlobalOAuthManager();
await oAuthManager.clearTokenCache();
print('Token缓存已清除');
```

### 测试文件

运行 `test_global_oauth.dart` 来测试全局OAuth管理器的功能：

```bash
flutter run test_global_oauth.dart
```

## 注意事项

1. **单例模式**: 全局OAuth管理器使用单例模式，确保整个应用使用同一个实例
2. **自动刷新**: token过期时会自动刷新，无需手动处理
3. **并发安全**: 多个请求同时等待token刷新时，会共享同一个刷新操作
4. **持久化**: token会自动保存到本地存储，应用重启后无需重新授权
5. **错误恢复**: 刷新失败时会自动尝试重新授权

## 迁移指南

如果您的代码中还在使用旧的OAuthService，请按以下步骤迁移：

1. 将 `import '../../pages/coze_page/o_auth_service.dart'` 改为 `import '../../utils/global_oauth_manager.dart'`
2. 将 `OAuthService` 改为 `GlobalOAuthManager`
3. 在构造函数中传入 `GlobalOAuthManager()` 实例
4. 调用 `getAccessToken()` 方法获取token

示例：

```dart
// 旧代码
final oAuthService = OAuthService();
final token = await oAuthService.getAccessToken();

// 新代码
final oAuthManager = GlobalOAuthManager();
await oAuthManager.initialize();
final token = await oAuthManager.getAccessToken();
```


