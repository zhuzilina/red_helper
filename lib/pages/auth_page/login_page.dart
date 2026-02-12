import 'package:flutter/material.dart';
import 'package:red_helper/utils/global_oauth_manager.dart';
import 'package:red_helper/route/routes.dart';
import 'package:red_helper/repository/api/login_api.dart'; // 确保导入正确的API服务

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        // 使用更新后的API服务
        final response = await ApiService.login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        // 保存"记住登录状态"选项
        if (_rememberMe) {
          // 已经在ApiService.login中处理了令牌保存
        }

        final oAuthManager = GlobalOAuthManager();
        try {
          await oAuthManager.initialize();
          await oAuthManager.getAccessToken();
        } catch (e) {
          throw ('oauth token获取失败$e');
        }

        // 导航到主页
        Navigator.pushNamedAndRemoveUntil(
          context,
          RoutePath.main,
          (route) => false,
        );
      } on FormatException catch (e) {
        _showErrorDialog(e.message);
      } catch (e) {
        _showErrorDialog('登录失败: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('登录失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 手机号验证正则表达式
  bool _isValidPhone(String value) {
    final phoneRegExp = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegExp.hasMatch(value);
  }

  // 密码强度验证
  bool _isValidPassword(String value) {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const AuthHeader(title: '欢迎登录'),
              const SizedBox(height: 40),
              AuthInput(
                controller: _identifierController,
                hintText: '请输入手机号或用户名',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入手机号或用户名';
                  }
                  // 如果是手机号格式，验证手机号
                  if (value.contains(RegExp(r'^1[3-9]'))) {
                    if (!_isValidPhone(value)) {
                      return '请输入有效的手机号';
                    }
                  }
                  // 用户名验证（至少3个字符）
                  else if (value.length < 3) {
                    return '用户名至少3个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AuthInput(
                controller: _passwordController,
                hintText: '请输入密码',
                isPassword: _obscurePassword,
                icon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (!_isValidPassword(value)) {
                    return '密码至少8个字符，包含大小写字母和数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // 记住登录状态选项
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                    ),
                    Text('记住登录状态'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RoutePath.forgotPassword,
                      ),
                      child: Text('忘记密码？'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AuthButton(
                onPressed: _handleLogin,
                isLoading: _isLoading,
                buttonText: '登 录',
              ),
              const SizedBox(height: 20),
              AuthLink(
                promptText: '没有账号？',
                linkText: '立即注册',
                onTap: () => Navigator.pushNamed(context, RoutePath.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String buttonText;

  const AuthButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(buttonText),
    );
  }
}

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String imagePath;

  const AuthHeader({
    super.key,
    required this.title,
    this.imagePath = 'assets/images/icon.png',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(imagePath, width: 120, height: 120),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final TextInputType? keyboardType; // 新增：支持指定键盘类型（如手机号用数字键盘）

  const AuthInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.icon = Icons.person,
    this.validator,
    this.suffixIcon,
    this.keyboardType, // 默认为文本键盘
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      keyboardType: keyboardType, // 优化输入键盘类型
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface, // 输入文字颜色适配主题
      ),
      decoration: InputDecoration(
        // 前缀图标（核心：确保图标显示并适配主题）
        prefixIcon: Icon(
          icon,
          color: colorScheme.onSurface.withOpacity(0.6), // 图标颜色半透明，避免过于刺眼
          size: 20, // 图标大小适中
        ),
        // 提示文字样式
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5), // 提示文字浅色化
        ),
        // 后缀图标（如密码可见性按钮）
        suffixIcon: suffixIcon != null
            ? IconTheme(
                data: IconThemeData(
                  color: colorScheme.onSurface.withOpacity(0.6), // 统一后缀图标颜色
                ),
                child: suffixIcon!,
              )
            : null,
        // 输入框背景
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.8), // 浅色背景，提升可读性
        // 边框样式（核心优化：添加状态边框反馈）
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 圆角边框，与按钮风格统一
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.2), // 默认边框浅色
            width: 1,
          ),
        ),
        // 焦点状态边框（交互反馈）
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.secondary, // 焦点时使用主题强调色
            width: 1.5, // 焦点边框稍粗，突出显示
          ),
        ),
        // 错误状态边框（验证反馈）
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error, // 错误时使用主题错误色
            width: 1,
          ),
        ),
        // 错误提示样式
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
          height: 1.2, // 减少错误提示占用的垂直空间
        ),
        // 内容内边距（避免文字/图标被挤压）
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16, // 垂直内边距增加，提升点击区域
          horizontal: 16,
        ),
        // 去除默认边距，避免与外部间距冲突
        isDense: true,
      ),
    );
  }
}

class AuthLink extends StatelessWidget {
  final String promptText;
  final String linkText;
  final VoidCallback onTap;

  const AuthLink({
    super.key,
    required this.promptText,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: RichText(
        text: TextSpan(
          text: promptText,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children: [
            TextSpan(
              text: linkText,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
