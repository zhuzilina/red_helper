import 'package:flutter/material.dart';
import 'package:red_helper/repository/api/login_api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        _showErrorDialog('请同意用户协议和隐私政策');
        return;
      }

      try {
        setState(() => _isLoading = true);

        // 调用注册API
        final response = await ApiService.register(
          phoneNumber: _phoneController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          //nickname: _nicknameController.text.trim(),
        );

        if (!mounted) return;

        // 显示注册成功消息
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'] ?? '注册成功')));

        // 注册成功后返回登录页面
        Navigator.pop(context);
      } on FormatException catch (e) {
        _showErrorDialog(e.message);
      } catch (e) {
        _showErrorDialog('注册失败: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('注册失败'),
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

  // 手机号验证
  bool _isValidPhone(String value) {
    final phoneRegExp = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegExp.hasMatch(value);
  }

  // 密码强度验证
  bool _isValidPassword(String value) {
    // 至少8个字符，包含大小写字母和数字
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return passwordRegExp.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          // 解决小屏幕键盘遮挡问题
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const AuthHeader(title: '创建账号'),
                const SizedBox(height: 30),
                AuthInput(
                  controller: _phoneController,
                  hintText: '请输入手机号',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone, // 优化键盘类型
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入手机号';
                    }
                    if (!_isValidPhone(value)) {
                      return '请输入有效的手机号';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                AuthInput(
                  controller: _usernameController,
                  hintText: '请输入用户名',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    if (value.length < 3) {
                      return '用户名至少3个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                AuthInput(
                  controller: _passwordController,
                  hintText: '请输入密码',
                  isPassword: _obscurePassword,
                  icon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
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
                const SizedBox(height: 15),
                AuthInput(
                  controller: _confirmPasswordController,
                  hintText: '请再次输入密码',
                  isPassword: _obscureConfirmPassword,
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请确认密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // 用户协议
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged:
                            (value) =>
                                setState(() => _agreedToTerms = value ?? false),
                        activeColor:
                            Theme.of(context).colorScheme.secondary, // 统一选中颜色
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: '我已阅读并同意',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.2, // 优化行高
                            ),
                            children: [
                              TextSpan(
                                text: ' 用户协议 ',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  decoration:
                                      TextDecoration.underline, // 下划线提示可点击
                                ),
                              ),
                              const TextSpan(text: '和'),
                              TextSpan(
                                text: ' 隐私政策',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AuthButton(
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                  buttonText: '注 册',
                ),
                const SizedBox(height: 20),
                AuthLink(
                  promptText: '已有账号？',
                  linkText: '立即登录',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 实现AuthInput组件（解决图标不显示问题）
class AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final Widget? suffixIcon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType; // 新增键盘类型参数

  const AuthInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.suffixIcon,
    required this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      keyboardType: keyboardType, // 优化输入键盘类型
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ), // 显示图标并设置颜色
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.5), // 提示文字颜色
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 圆角边框
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withOpacity(0.3), // 边框颜色
          ),
        ),
        focusedBorder: OutlineInputBorder(
          // 焦点状态边框
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary, // 焦点时边框颜色
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          // 错误状态边框
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error, // 错误时边框颜色
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16), // 输入框内边距
        errorStyle: TextStyle(
          // 错误提示样式
          fontSize: 12,
          height: 1, // 减少错误提示占用高度
        ),
      ),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface, // 输入文字颜色
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
      child:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          text: promptText,
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
