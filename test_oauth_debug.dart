import 'lib/pages/coze_page/o_auth_service.dart';
import 'lib/env.dart';

void main() async {
  print("🔍 开始详细OAuth调试测试...");
  
  try {
    // 检查配置
    print("\n📋 配置检查:");
    print("  Client ID: ${clientId.isNotEmpty ? '已设置' : '未设置'}");
    print("  Workflow ID: ${workflowId.isNotEmpty ? '已设置' : '未设置'}");
    
    if (clientId.isEmpty) {
      print("❌ Client ID未设置");
      return;
    }
    
    print("\n🔧 创建OAuth服务...");
    final oAuthService = OAuthService();
    
    print("⏳ 等待初始化...");
    await Future.delayed(const Duration(seconds: 2));
    
    print("\n🔐 尝试获取访问令牌...");
    print("⚠️ 注意：首次使用会打开浏览器进行授权");
    
    try {
      final accessToken = await oAuthService.getAccessToken();
      print("✅ OAuth认证成功！");
      print("🔑 Token长度: ${accessToken.length} 字符");
      print("🔑 Token预览: ${accessToken.substring(0, accessToken.length > 30 ? 30 : accessToken.length)}...");
      
    } catch (e) {
      print("❌ OAuth认证失败: $e");
      print("\n💡 可能的原因:");
      print("  1. 网络连接问题");
      print("  2. 浏览器无法打开");
      print("  3. 防火墙阻止");
      print("  4. OAuth配置错误");
      print("\n🔧 建议解决方案:");
      print("  1. 检查网络连接");
      print("  2. 确保浏览器可以正常打开");
      print("  3. 检查防火墙设置");
      print("  4. 验证Client ID是否正确");
    }
    
  } catch (e) {
    print("❌ 测试过程中发生异常: $e");
  }
}



