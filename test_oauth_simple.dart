import 'lib/pages/coze_page/o_auth_service.dart';

void main() async {
  print("🔍 开始简单OAuth测试...");
  
  try {
    print("🔧 创建OAuth服务...");
    final oAuthService = OAuthService();
    
    print("⏳ 等待初始化...");
    await Future.delayed(const Duration(seconds: 1));
    
    print("🔐 尝试获取访问令牌...");
    final accessToken = await oAuthService.getAccessToken();
    
    print("✅ OAuth认证成功！");
    print("🔑 Token长度: ${accessToken.length} 字符");
    print("🔑 Token预览: ${accessToken.substring(0, accessToken.length > 30 ? 30 : accessToken.length)}...");
    
  } catch (e) {
    print("❌ OAuth认证失败: $e");
    print("💡 提示：首次使用需要浏览器授权");
  }
}



