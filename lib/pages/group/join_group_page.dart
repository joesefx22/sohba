import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_state.dart';
import '../home/home_page.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = false;

  // Join fields
  final _joinFormKey = GlobalKey<FormState>();
  final _joinNameCtrl = TextEditingController();
  final _joinCodeCtrl = TextEditingController();

  // Create fields
  final _createFormKey = GlobalKey<FormState>();
  final _createNameCtrl = TextEditingController();
  final _createDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _joinNameCtrl.dispose();
    _joinCodeCtrl.dispose();
    _createNameCtrl.dispose();
    _createDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _doJoin() async {
    if (!_joinFormKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final userId = context.read<AuthProvider>().user!.id;
    final ok = await context.read<GroupProvider>().joinGroup(
          name: _joinNameCtrl.text,
          inviteCode: _joinCodeCtrl.text,
          userId: userId,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      _goHome();
    } else {
      AppSnackbar.error(
          context, context.read<GroupProvider>().error ?? 'فشل الانضمام');
    }
  }

  Future<void> _doCreate() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final userId = context.read<AuthProvider>().user!.id;
    final ok = await context.read<GroupProvider>().createGroup(
          name: _createNameCtrl.text,
          userId: userId,
          description: _createDescCtrl.text.isEmpty ? null : _createDescCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      _goHome();
    } else {
      AppSnackbar.error(
          context, context.read<GroupProvider>().error ?? 'فشل إنشاء المجموعة');
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('المجموعة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'انضمام'),
            Tab(text: 'إنشاء'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildJoinTab(),
            _buildCreateTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _joinFormKey,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_add, size: 56, color: Color(0xFFD4AF37)),
              const SizedBox(height: 16),
              const Text('انضم إلى مجموعة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _joinNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المجموعة',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'أدخل اسم المجموعة' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _joinCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'كود الدعوة (6 أحرف)',
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null || v.length != 6) ? 'الكود 6 أحرف' : null,
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                onPressed: _loading ? null : _doJoin,
                label: _loading ? 'جارٍ الانضمام...' : 'انضم',
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _createFormKey,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle, size: 56, color: Color(0xFFD4AF37)),
              const SizedBox(height: 16),
              const Text('أنشئ مجموعة جديدة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _createNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المجموعة',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? '3 أحرف على الأقل' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _createDescCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'وصف مختصر (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                onPressed: _loading ? null : _doCreate,
                label: _loading ? 'جارٍ الإنشاء...' : 'أنشئ',
                expanded: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'سيتم إنشاء كود دعوة تلقائيًا لمشاركته مع إخوانك',
                style: TextStyle(fontSize: 12, color: Colors.white60),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}