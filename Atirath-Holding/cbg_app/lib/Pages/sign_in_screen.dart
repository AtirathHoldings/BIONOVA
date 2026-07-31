import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// =============================================
// TOP WAVE BACKGROUND
// =============================================
class SignInWaveBackground extends StatelessWidget {
  const SignInWaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TopWavePainter(),
      child: const SizedBox.expand(),
    );
  }
}


class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Main blue-purple gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF6D20FF),
          Color(0xFF3566FF),
          Color(0xFF16B8FF),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    // Purple back wave
    final purplePath = Path();
    purplePath.moveTo(0, size.height * 0.70);

    purplePath.cubicTo(
      size.width * 0.18, size.height * 0.58,
      size.width * 0.34, size.height * 0.60,
      size.width * 0.48, size.height * 0.78,
    );

    purplePath.cubicTo(
      size.width * 0.62, size.height * 0.95,
      size.width * 0.82, size.height * 0.84,
      size.width, size.height * 0.72,
    );

    purplePath.lineTo(size.width, size.height);
    purplePath.lineTo(0, size.height);
    purplePath.close();

    final purplePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF5D1BFF),
          Color(0xFF6E1FFF),
          Color(0xFF7A21FF),
        ],
      ).createShader(rect);

    canvas.drawPath(purplePath, purplePaint);

    // White front wave
    final whitePath = Path();
    whitePath.moveTo(0, size.height * 0.78);

    whitePath.cubicTo(
      size.width * 0.15, size.height * 0.64,
      size.width * 0.32, size.height * 0.66,
      size.width * 0.48, size.height * 0.84,
    );

    whitePath.cubicTo(
      size.width * 0.63, size.height * 1.00,
      size.width * 0.84, size.height * 0.88,
      size.width, size.height * 0.76,
    );

    whitePath.lineTo(size.width, size.height);
    whitePath.lineTo(0, size.height);
    whitePath.close();

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawPath(whitePath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================
// MAIN SIGN IN PAGE
// =============================================
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _loginError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail');
    final savedPassword = prefs.getString('savedPassword');
    
    if (savedEmail != null && savedPassword != null) {
      if (mounted) {
        setState(() {
          _usernameController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    print('BASE_URL: ${dotenv.env['BASE_URL']}');

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _loginError = null;
        _emailError = null;
      });

      try {
        final response = await http.post(
          Uri.parse('${dotenv.env['BASE_URL']}/api/auth/login'),
          headers: {
            'key': 'value',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': _usernameController.text.trim(),
            'password': _passwordController.text.trim(),
          }),
        ).timeout(const Duration(seconds: 10));

        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            print('Login successful: $data');
            
            final prefs = await SharedPreferences.getInstance();
            
            // Handle Remember Me
            if (_rememberMe) {
              await prefs.setString('savedEmail', _usernameController.text.trim());
              await prefs.setString('savedPassword', _passwordController.text.trim());
            } else {
              await prefs.remove('savedEmail');
              await prefs.remove('savedPassword');
            }
            
            // Purge previous employee cache
            await ApiService.clearCache();

            final String? tokenStr = (data['token'] ?? data['accessToken'] ?? data['jwt'] ?? data['jwtToken'] ?? data['data']?['token'])?.toString();
            if (tokenStr != null && tokenStr.isNotEmpty) {
              await prefs.setString('authToken', tokenStr);
            }
            if (data['role'] != null) {
              await prefs.setString('userRole', data['role']);
            }
            await prefs.setString('userEmail', _usernameController.text.trim());
            
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/main',
              );
            }
            return;
          } else {
            setState(() {
              final errMsg = data['message'] ?? 'Invalid email or password.';
              _loginError = errMsg;
              _emailError = errMsg;
            });
          }
        } else if (response.statusCode == 401 || response.statusCode == 400) {
          setState(() {
            _loginError = 'Invalid email or password. Please try again.';
            _emailError = 'Invalid email or password';
          });
        } else {
          setState(() {
            _loginError = 'Server error (${response.statusCode}). Please try again later.';
          });
        }
      } catch (e) {
        print('Error during login: $e');
        setState(() {
          _loginError = 'Connection failed. Please check your internet connection.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // =============================================
  // SIMPLIFIED FORGOT PASSWORD DIALOG - CORRECTED
  // =============================================
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Forgot Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your registered email address to receive a password reset link.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isSubmitting,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: errorMessage,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          // Clear previous errors
                          setStateDialog(() {
                            errorMessage = null;
                            isSubmitting = true;
                          });

                          try {
                            print('=== SENDING PASSWORD RESET LINK ===');
                            print('Email: ${emailController.text.trim()}');
                            print('Base URL: ${dotenv.env['BASE_URL']}');
                            
                            final message = await ApiService.sendPasswordResetLink(
                              emailController.text.trim(),
                            );

                            print('Success: $message');

                            if (!mounted) return;

                            // Close dialog
                            Navigator.pop(dialogContext);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        message,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green.shade700,
                                duration: const Duration(seconds: 5),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
                            
                            print('Error: $errorMsg');
                            
                            setStateDialog(() {
                              errorMessage = errorMsg.isNotEmpty 
                                  ? errorMsg 
                                  : 'Could not send reset link. Please try again.';
                              isSubmitting = false;
                            });
                          } finally {
                            if (mounted) {
                              setStateDialog(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2469F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================
                    // TOP BLUE SECTION
                    // =========================
                    SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          // Wave Background
                          const Positioned.fill(
                            child: SignInWaveBackground(),
                          ),

                          // Logo inside blue area
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),

                                // LOGO
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    child: Image.asset(
                                      'assets/Bionova_Logo.webp',
                                      height: 72,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.account_circle,
                                          size: 72,
                                          color: Color(0xFF2469F5),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =========================
                    // FORM SECTION
                    // =========================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // WELCOME TEXT
                            const Text(
                              'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Sign in to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                            
                            const SizedBox(height: 32),

                            // Email Field
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.emailAddress,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onChanged: (val) {
                                if (_emailError != null) {
                                  setState(() {
                                    _emailError = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 16,
                                ),
                                errorText: _emailError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFBDBDBD),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2469F5),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFBDBDBD),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2469F5),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF2469F5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Remember me'),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2469F5),
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),

                            if (_loginError != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _loginError!,
                                        style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}