import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await context
        .read<AuthProvider>()
        .sendPasswordReset(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (ok) _sent = true;
    });

    if (!ok) {
      final err = context.read<AuthProvider>().error;
      AppSnackbar.error(context, err ?? 'تعذّر الإرسال');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('استرجاع كلمة المرور'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _sent ? _sentState() : _formState(),
          ),
        ),
      ),
    );
  }

  Widget _formState() {
    return Form(
      key: _formKey,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset, size: 56, color: AppColors.gold),
            const SizedBox(height: 16),
            Text('نسيت كلمة المرور؟',
                style: AppText.section.copyWith(fontSize: 22),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
              style: AppText.caption.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _loading ? null : _submit(),
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'أدخل بريدك الإلكتروني';
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return 'بريد غير صالح';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              onPressed: _loading ? null : _submit,
              label: _loading ? 'جارٍ الإرسال...' : 'أرسل الرابط',
              expanded: true,
              isLoading: _loading,
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentState() {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.emerald.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                size: 38, color: AppColors.mint),
          ),
          const SizedBox(height: 20),
          Text('تم الإرسال',
              style: AppText.section.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            'إن كان البريد مسجّلًا، فسيصلك رابط استرجاع خلال دقائق.\n'
            'راجع مجلد الـ Spam إن لم تجده.',
            style: AppText.caption.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withAlpha(80)),
            ),
            child: SelectableText(
              _emailCtrl.text.trim(),
              style: AppText.body.copyWith(
                  color: AppColors.goldBright, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          AppButton.secondary(
            onPressed: () => Navigator.of(context).pop(),
            label: 'رجوع لتسجيل الدخول',
            expanded: true,
            icon: Icons.arrow_back,
          ),
        ],
      ),
    );
  }
}