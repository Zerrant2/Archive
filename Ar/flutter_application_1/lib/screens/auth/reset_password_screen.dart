// lib/screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final List<TextEditingController> _codeControllers = List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _codeVerified = false;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _enteredCode => _codeControllers.map((c) => c.text).join();

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.recovery,
        email: widget.email,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Код отправлен повторно на вашу почту"),
            backgroundColor: Color(0xFF40C97A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ошибка отправки кода"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyResetCode() async {
    final code = _enteredCode.trim();
    if (code.length != 8) {
      setState(() => _errorMessage = "Введите полный 8-значный код");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.recovery,
      );
      setState(() => _codeVerified = true);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Неверный код");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Пароли не совпадают");
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = "Пароль должен быть не менее 6 символов");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Пароль успешно изменён!"), backgroundColor: Color(0xFF40C97A)),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = "Ошибка смены пароля");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 7) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
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
                const SizedBox(height: 60),

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
                      const Icon(Icons.lock_reset, size: 60, color: Color(0xFF40C97A)),
                      const SizedBox(height: 16),

                      Text(
                        _codeVerified ? "Новый пароль" : "Сброс пароля",
                        style: const TextStyle(
                          color: AppColors.blueText,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Itim',
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _codeVerified 
                            ? "Придумайте новый пароль" 
                            : "Мы отправили 8-значный код на\n${widget.email}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.blueText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!_codeVerified)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(8, (index) {
                            return SizedBox(
                              width: 40,
                              child: TextField(
                                controller: _codeControllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (value) => _onCodeChanged(index, value),
                              ),
                            );
                          }),
                        )
                      else ...[
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: "Новый пароль",
                            labelStyle: const TextStyle(color: AppColors.blueText, fontSize: 15),
                            filled: true,
                            fillColor: const Color(0xFFF8E0E0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Подтвердите пароль",
                            labelStyle: const TextStyle(color: AppColors.blueText, fontSize: 15),
                            filled: true,
                            fillColor: const Color(0xFFF8E0E0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                      ],

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_codeVerified ? _updatePassword : _verifyResetCode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCC6665),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _codeVerified ? "Изменить пароль" : "Подтвердить",
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                        ),
                      ),

                      if (!_codeVerified)
                        TextButton(
                          onPressed: _resendCode,
                          child: const Text(
                            "Отправить код повторно",
                            style: TextStyle(color: Color(0xFF40C97A)),
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