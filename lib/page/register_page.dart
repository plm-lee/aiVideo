import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/service/auth_service.dart';
import 'dart:math';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isVerificationCodeSent = false;
  int _countDown = 60;
  bool _isCountingDown = false;

  // 添加输入监听
  bool _isFormValid = false;
  String? _emailError;
  String? _verificationCodeError;
  String? _passwordError;
  String? _confirmPasswordError;

  // 添加邮箱验证正则表达式
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // 添加邮箱有效性状态
  bool get _isEmailValid => _emailRegex.hasMatch(_emailController.text);

  @override
  void initState() {
    super.initState();
    // 添加输入监听
    _emailController.addListener(_validateForm);
    _verificationCodeController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 表单验证
  void _validateForm() {
    setState(() {
      // 验证邮箱
      if (_emailController.text.isEmpty) {
        _emailError = 'Email is required';
      } else if (!_emailRegex.hasMatch(_emailController.text)) {
        _emailError = 'Please enter a valid email';
      } else {
        _emailError = null;
      }

      // 验证验证码
      if (_verificationCodeController.text.isEmpty) {
        _verificationCodeError = 'Verification code is required';
      } else {
        _verificationCodeError = null;
      }

      // 验证密码
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password is required';
      } else {
        _passwordError = null;
      }

      // 检查所有字段是否有效
      _isFormValid = _emailError == null &&
          _verificationCodeError == null &&
          _passwordError == null &&
          _emailController.text.isNotEmpty &&
          _verificationCodeController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  void _handleRegister() async {
    try {
      final result = await AuthService().register(
        email: _emailController.text,
        verificationCode: _verificationCodeController.text,
        password: _passwordController.text,
      );

      if (result.success) {
        // 注册成功，跳转登录页面
        if (mounted) {
          context.go('/login');
        }
      } else {
        // 注册失败，显示错误信息
        if (mounted) {
          setState(() {
            _emailError = result.message ?? 'Registration failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailError = 'Error during registration';
        });
      }
      debugPrint('Register error: $e');
    }
  }

  void _startCountDown() {
    setState(() {
      _isVerificationCodeSent = true;
      _isCountingDown = true;
      _countDown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _countDown--;
      });

      if (_countDown <= 0) {
        setState(() {
          _isCountingDown = false;
        });
        return false;
      }
      return true;
    });
  }

  void _sendVerificationCode() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      return;
    }

    if (!_emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return;
    }

    try {
      final result =
          await AuthService().sendVerificationCode(_emailController.text);

      if (result) {
        // 发送成功，开始倒计时
        _startCountDown();
      } else {
        // 发送失败，显示错误
        setState(() {
          _emailError = 'Failed to send verification code';
        });
      }
    } catch (e) {
      setState(() {
        _emailError = 'Error sending verification code';
      });
      debugPrint('Send verification code error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D1F3D),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 添加星星背景效果
            Positioned.fill(
              child: CustomPaint(
                painter: StarFieldPainter(),
              ),
            ),
            // Logo 和标题
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SafeArea(
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.jpg',
                        height: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ChatMax',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 注册表单
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  margin: const EdgeInsets.only(top: 80),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign up to get started',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Email输入框
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.email, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _emailError != null
                                ? const BorderSide(color: Colors.red, width: 1)
                                : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _emailError != null
                                ? const BorderSide(color: Colors.red, width: 1)
                                : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _emailError != null
                                ? const BorderSide(color: Colors.red, width: 2)
                                : const BorderSide(
                                    color: Color(0xFFFF69B4), width: 2),
                          ),
                          errorText: _emailError,
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 验证码输入框和发送按钮
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _verificationCodeController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              maxLength: 9,
                              decoration: InputDecoration(
                                hintText: 'Verification Code',
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.security,
                                    color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: _verificationCodeError != null
                                      ? const BorderSide(
                                          color: Colors.red, width: 1)
                                      : BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: _verificationCodeError != null
                                      ? const BorderSide(
                                          color: Colors.red, width: 1)
                                      : BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: _verificationCodeError != null
                                      ? const BorderSide(
                                          color: Colors.red, width: 2)
                                      : const BorderSide(
                                          color: Color(0xFFFF69B4), width: 2),
                                ),
                                counterText: '',
                                errorText: _verificationCodeError,
                                errorStyle: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (_isCountingDown || !_isEmailValid)
                                  ? null
                                  : _sendVerificationCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF69B4),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(100, 48),
                                maximumSize: const Size(100, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: Text(
                                _isCountingDown ? '$_countDown s' : 'Send',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 密码输入框
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _passwordError != null
                                ? const BorderSide(color: Colors.red, width: 1)
                                : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _passwordError != null
                                ? const BorderSide(color: Colors.red, width: 1)
                                : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: _passwordError != null
                                ? const BorderSide(color: Colors.red, width: 2)
                                : const BorderSide(
                                    color: Color(0xFFFF69B4), width: 2),
                          ),
                          errorText: _passwordError,
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // 注册按钮
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isFormValid ? _handleRegister : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF69B4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 底部登录链接
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFFFF69B4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 添加 StarFieldPainter
class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random();
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 100; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = random.nextDouble() * 1.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
