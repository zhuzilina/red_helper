# OAuth Token问题分析

## 问题描述

从应用日志中可以看到，OAuth token获取成功，但在调用API时仍然返回401错误：

```
✅ 成功获取访问令牌，长度: 69 字符
🔑 Token预览: czu_qXNjpmqcFP6TX7OW...
📥 收到响应，状态码: 401
❌ 错误响应体: {"code":700012006,"msg":"access token invalid"}
```

## 问题分析

### 1. Token获取成功但API调用失败

**现象**：
- OAuth授权流程正常完成
- Token成功获取并保存
- Token格式正确（以`czu_`开头）
- 但在API调用时返回401错误

**可能原因**：
1. **API端点权限问题**：workflow API可能需要特定的权限
2. **Token作用域问题**：获取的token可能没有访问workflow API的权限
3. **API版本问题**：可能需要使用不同的API版本
4. **OAuth应用配置问题**：OAuth应用可能没有正确的权限配置

### 2. 配置检查

**当前配置**：
- Client ID: `23082449719795571320238051220083.app.coze`
- Question Client ID: `23082449719795571320238051220083.app.coze`
- Workflow ID: `7536844432798629907`
- Question Bot ID: `7536839060884078627`

**问题**：
- 使用了两个不同的clientId，可能导致权限混乱
- 需要确认OAuth应用是否有访问workflow API的权限

## 解决方案

### 1. 创建诊断工具

已创建 `lib/utils/oauth_diagnostic.dart` 来帮助调试：

```dart
final diagnostic = OAuthDiagnostic();
await diagnostic.runDiagnostic();
```

### 2. 测试不同的API端点

诊断工具会测试以下API端点：
- `https://api.coze.cn/v1/workflow/run` - Workflow API
- `https://api.coze.cn/v3/chat` - Chat API  
- `https://api.coze.cn/v1/bot/list` - Bot List API

### 3. 检查权限

诊断工具会检查：
- Token格式是否正确
- 用户信息API是否可访问
- 不同API端点的权限

## 调试步骤

### 步骤1：运行诊断工具

```bash
flutter run lib/utils/oauth_diagnostic.dart
```

### 步骤2：检查OAuth应用配置

1. 登录Coze平台
2. 检查OAuth应用的权限配置
3. 确认是否有访问workflow API的权限

### 步骤3：测试不同的API端点

如果workflow API不可用，可以尝试：
1. 使用Chat API替代
2. 检查API文档确认正确的端点
3. 验证请求格式是否正确

### 步骤4：检查Token作用域

确认OAuth应用配置了正确的权限范围（scope）。

## 临时解决方案

如果OAuth API调用持续失败，可以：

1. **使用模拟数据**：继续使用当前的模拟数据功能
2. **降级到Chat API**：使用更简单的Chat API
3. **检查API文档**：确认正确的API端点和权限要求

## 下一步行动

1. **运行诊断工具**：获取详细的错误信息
2. **检查OAuth应用配置**：确认权限设置
3. **测试不同的API端点**：找到可用的API
4. **更新API调用**：使用正确的端点和格式

## 相关文件

- `lib/utils/oauth_diagnostic.dart` - OAuth诊断工具
- `lib/utils/global_oauth_manager.dart` - 全局OAuth管理器
- `lib/pages/content_page/super_page/generate.dart` - API调用逻辑
- `lib/env.dart` - 配置文件

## 总结

OAuth token获取功能工作正常，但API调用失败。这通常是权限配置问题，需要通过诊断工具进一步分析具体原因。


