// lib/screens/auth/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';


class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyCode() async {
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
        type: OtpType.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Почта успешно подтверждена!"),
            backgroundColor: Color(0xFF40C97A),
          ),
        );
        Navigator.pushReplacementNamed(context, '/studio');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Неверный код подтверждения");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
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
          const SnackBar(
            content: Text("Ошибка отправки кода"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                      const Icon(Icons.mark_email_unread, size: 60, color: Color(0xFF40C97A)),
                      const SizedBox(height: 16),

                      const Text(
                        'Подтверждение почты',
                        style: TextStyle(
                          color: AppColors.blueText,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Itim',
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Мы отправили 8-значный код на\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.blueText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(8, (index) {
                          return SizedBox(
                            width: 40,
                            child: TextField(
                              controller: _controllers[index],
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
                      ),

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
                          onPressed: _isLoading ? null : _verifyCode,
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
                              : const Text(
                                  'Подтвердить',
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _resendCode,
                        child: const Text(
                          'Отправить код повторно',
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