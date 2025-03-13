import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/service/auth_service.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isSendingCode = false;
  bool _isAgreeToTerms = false;
  Timer? _timer;

  // 移除实时验证相关变量
  String? _emailError;
  String? _verificationCodeError;
  String? _passwordError;

  // 添加邮箱验证正则表达式
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // 添加邮箱有效性状态
  bool get _isEmailValid => _emailRegex.hasMatch(_emailController.text);

  @override
  void initState() {
    super.initState();
    // 移除输入监听
  }

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel(); // 取消定时器
    super.dispose();
  }

  void _handleRegister() async {
    // 点击时进行验证
    if (!_validateForm()) {
      return;
    }

    try {
      final result = await AuthService().register(
        email: _emailController.text,
        verificationCode: _verificationCodeController.text,
        password: _passwordController.text,
      );

      if (result.success) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Registration Successful',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Would you like to login now?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                          child: const Text('Later'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/login');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                          child: const Text('Login Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      } else {
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

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      // 验证邮箱
      if (_emailController.text.isEmpty) {
        _emailError = 'Email is required';
        isValid = false;
      } else if (!_emailRegex.hasMatch(_emailController.text)) {
        _emailError = 'Please enter a valid email';
        isValid = false;
      } else {
        _emailError = null;
      }

      // 验证验证码
      if (_verificationCodeController.text.isEmpty) {
        _verificationCodeError = 'Verification code is required';
        isValid = false;
      } else {
        _verificationCodeError = null;
      }

      // 验证密码
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password is required';
        isValid = false;
      } else {
        _passwordError = null;
      }

      // 验证用户协议
      if (!_isAgreeToTerms) {
        isValid = false;
      }
    });
    return isValid;
  }

  void _startCountDown() {
    setState(() {
      _isVerificationCodeSent = true;
      _isCountingDown = true;
      _countDown = 60;
    });

    _timer?.cancel(); // 确保之前的定时器被取消
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countDown > 0) {
          _countDown--;
        } else {
          _isCountingDown = false;
          timer.cancel();
        }
      });
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

    setState(() {
      _isSendingCode = true;
      _emailError = null; // Clear previous error message
    });

    try {
      final result =
          await AuthService().sendVerificationCode(_emailController.text);

      if (mounted) {
        if (result) {
          // Start countdown if code sent successfully
          _startCountDown();
        } else {
          setState(() {
            _emailError = 'Failed to send verification code';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailError = 'Error sending verification code';
        });
      }
      debugPrint('Send verification code error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      debugPrint('Error opening link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening link'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        'assets/images/logo.png',
                        height: 32,
                        width: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'MagaVideo',
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
                              onPressed: (_isCountingDown || _isSendingCode)
                                  ? null
                                  : () {
                                      if (_isEmailValid) {
                                        _sendVerificationCode();
                                      } else {
                                        setState(() {
                                          _emailError =
                                              'Please enter a valid email';
                                        });
                                      }
                                    },
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
                              child: _isSendingCode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _isCountingDown
                                          ? '$_countDown s'
                                          : 'Send',
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
                                  ? Icons.visibility
                                  : Icons.visibility_off,
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
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF8C8C),
                              Color(0xFFFF69B4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ElevatedButton(
                          onPressed: _isAgreeToTerms ? _handleRegister : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 用户协议
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(4),
                            child: Transform.scale(
                              scale: 1.2,
                              child: CupertinoCheckbox(
                                value: _isAgreeToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _isAgreeToTerms = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFFFF69B4),
                                checkColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                      text: 'I have read and agree to '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(
                                      color: Color(0xFFFF69B4),
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _launchURL(
                                          'https://chat.bigchallenger.com/terms_services',
                                        );
                                      },
                                  ),
                                  const TextSpan(text: ', '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: Color(0xFFFF69B4),
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _launchURL(
                                          'https://chat.bigchallenger.com/privacy_policies',
                                        );
                                      },
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Licenses',
                                    style: const TextStyle(
                                      color: Color(0xFFFF69B4),
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _launchURL(
                                          'https://chat.bigchallenger.com/licenses',
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
