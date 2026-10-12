import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_state.dart';
import '../splash_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await context.read<AuthProvider>().signUp(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          name: _nameCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case SignUpResult.success:
        // Logged in immediately — jump to splash which routes to
        // JoinGroupPage or HomePage.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashPage()),
          (_) => false,
        );
        break;

      case SignUpResult.needsEmailConfirmation:
        _showConfirmationDialog();
        break;

      case SignUpResult.error:
        final err = context.read<AuthProvider>().error;
        AppSnackbar.error(context, err ?? 'فشل التسجيل');
        break;
    }
  }

  void _showConfirmationDialog() {
    final email = context.read<AuthProvider>().pendingEmail ?? _emailCtrl.text;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_outlined,
                color: AppColors.gold, size: 24),
            SizedBox(width: 10),
            Text(
              'راجع بريدك',
              style: TextStyle(color: AppColors.text),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أرسلنا رابط تأكيد إلى:',
              style: AppText.body,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withAlpha(80)),
              ),
              child: SelectableText(
                email,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(
                  color: AppColors.goldBright,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'افتح الرابط لتفعيل حسابك، ثم ارجع وسجّل الدخول.',
              style: AppText.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final ok =
                  await context.read<AuthProvider>().resendConfirmationEmail();
              if (!dialogCtx.mounted) return;
              if (ok) {
                AppSnackbar.success(dialogCtx, 'تم إرسال الرابط مرة أخرى');
              } else {
                AppSnackbar.error(dialogCtx, 'تعذّر الإرسال — حاول لاحقًا');
              }
            },
            child: const Text(
              'أعد الإرسال',
              style: TextStyle(color: AppColors.mint),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop(); // back to login
            },
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add,
                        size: 56, color: AppColors.gold),
                    const SizedBox(height: 16),
                    Text(
                      'انضم إلى صحبة',
                      style: AppText.section.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'أدخل اسمك'
                          : null,
                    ),
                    const SizedBox(height: 16),
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
                      validator: (v) {
                        if (v == null || !v.contains('@') || !v.contains('.')) {
                          return 'بريد غير صالح';
                        }
                        return null;
                      },
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
                      validator: (v) =>
                          (v == null || v.length < 6)
                              ? '6 أحرف على الأقل'
                              : null,
                    ),
                    const SizedBox(height: 24),
                    AppButton.primary(
                      onPressed: _loading ? null : _submit,
                      label: _loading ? 'جارٍ التسجيل...' : 'إنشاء الحساب',
                      expanded: true,
                      isLoading: _loading,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('لديك حساب بالفعل؟ سجّل الدخول'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}