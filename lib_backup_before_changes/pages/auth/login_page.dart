import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_state.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';                       // ← جديد

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await context.read<AuthProvider>().signIn(
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      final err = context.read<AuthProvider>().error;
      AppSnackbar.error(context, err ?? 'فشل تسجيل الدخول');
    }
    // Auto-navigation on success is handled by the `auth.isLoggedIn`
    // watcher below (see build method).
  }

  // ✅ _sendReset اتشالت — دلوقتي الـ navigation لصفحة مستقلة.

  @override
  Widget build(BuildContext context) {
    // Auto-navigate when auth succeeds (e.g. after signup with session).
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/splash',
          (_) => false,
        );
      });
    }

    return GlassScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mosque, size: 80, color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text(
                    'صحبة',
                    style: AppText.heading.copyWith(
                      fontSize: 48,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'رفيقك على طريق الطاعة',
                    style: AppText.body.copyWith(
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 40),
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'بريد غير صالح'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loading ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'أدخل كلمة المرور'
                              : null,
                        ),
                        const SizedBox(height: 8),

                        // ✅ زر "نسيت كلمة المرور؟" → ينقل لصفحة مستقلة
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                color: AppColors.mint,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        AppButton.primary(
                          onPressed: _loading ? null : _submit,
                          label: _loading
                              ? 'جارٍ الدخول...'
                              : 'تسجيل الدخول',
                          expanded: true,
                          isLoading: _loading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SignupPage()),
                      );
                    },
                    child: const Text(
                        'ليس لديك حساب؟ أنشئ حسابًا جديدًا'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}