// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Заполните все поля");
      return;
    }

    if (password != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Пароли не совпадают");
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = "Пароль должен быть не менее 6 символов");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': username,
          'phone': phone,
        },
      );

      if (response.user != null && mounted) {
        final needsEmailVerification = response.user?.emailConfirmedAt == null;
        
        if (needsEmailVerification) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Код подтверждения отправлен на вашу почту!"),
              backgroundColor: Color(0xFF40C97A),
            ),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(email: email),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Регистрация успешна!"),
              backgroundColor: Color(0xFF40C97A),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Ошибка регистрации");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAC1D1D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'АРхив',
                  style: TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 30),

                Container(
                  width: 375,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Регистрация',
                        style: TextStyle(
                          color: AppColors.blueText,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Itim',
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Имя пользователя',
                          labelStyle: const TextStyle(color: AppColors.blueText, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFF8E0E0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          labelStyle: const TextStyle(color: AppColors.blueText, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFF8E0E0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.blueText,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Подтвердите пароль',
                          labelStyle: const TextStyle(color: AppColors.blueText, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFF8E0E0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.blueText,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Номер телефона',
                          labelStyle: const TextStyle(color: AppColors.blueText, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFF8E0E0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Адрес электронной почты',
                          labelStyle: const TextStyle(color: AppColors.blueText, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFF8E0E0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: _isLoading ? null : _register,
                        child: Container(
                          width: 307,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCC6665),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Зарегистрироваться',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}