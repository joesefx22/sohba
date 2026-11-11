import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../repositories/qiyam_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class QiyamPage extends StatefulWidget {
  /// When `true`, the page renders as an embedded tab (no AppBar).
  final bool embedded;

  const QiyamPage({super.key, this.embedded = false});

  @override
  State<QiyamPage> createState() => _QiyamPageState();
}

class _QiyamPageState extends State<QiyamPage> {
  bool _loading = true;
  bool _saving = false;

  bool _witr = false;
  bool _shaf = false;
  bool _duha = false;
  int _sunnahRakat = 0;
  int _tahajjudRakat = 0;
  int _duaCount = 0;

  late final QiyamRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = QiyamRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _loading = true);
    try {
      final data = await _repo.getRange(userId: userId, days: 1);
      final todayKey = _dateKey(DateTime.now());
      final row = data[todayKey];
      setState(() {
        _witr = row?['witr'] == true;
        _shaf = row?['shaf'] == true;
        _duha = row?['duha'] == true;
        _sunnahRakat = (row?['sunnah_rakat'] as num?)?.toInt() ?? 0;
        _tahajjudRakat = (row?['tahajjud_rakat'] as num?)?.toInt() ?? 0;
        _duaCount = (row?['dua_count'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      debugPrint('QiyamPage._load: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _saving = true);
    try {
      await _repo.log(
        userId: userId,
        witr: _witr,
        shaf: _shaf,
        duha: _duha,
        sunnahRakat: _sunnahRakat,
        tahajjudRakat: _tahajjudRakat,
        duaCount: _duaCount,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'تم الحفظ');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'فشل الحفظ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.mint),
          )
        : _buildContent();

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: content),
      );
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('القيام والسنن'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تسجيل اليوم',
                  style: AppText.section.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('صليت الشفع'),
                value: _shaf,
                onChanged: (v) => setState(() => _shaf = v),
                activeThumbColor: AppColors.emerald,
              ),
              SwitchListTile(
                title: const Text('صليت الوتر'),
                value: _witr,
                onChanged: (v) => setState(() => _witr = v),
                activeThumbColor: AppColors.emerald,
              ),
              SwitchListTile(
                title: const Text('صليت الضحى'),
                value: _duha,
                onChanged: (v) => setState(() => _duha = v),
                activeThumbColor: AppColors.emerald,
              ),
              const Divider(height: 24),
              _counter(
                'ركعات السنة',
                _sunnahRakat,
                (v) => setState(() => _sunnahRakat = v),
                max: 20,
              ),
              _counter(
                'ركعات التهجد',
                _tahajjudRakat,
                (v) => setState(() => _tahajjudRakat = v),
                max: 20,
              ),
              _counter(
                'عدد الدعوات في القيام',
                _duaCount,
                (v) => setState(() => _duaCount = v),
                max: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.check),
          label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }

  Widget _counter(
    String label,
    int value,
    ValueChanged<int> onChange, {
    int max = 99,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppText.body.copyWith(fontSize: 14)),
          ),
          IconButton(
            onPressed: value > 0 ? () => onChange(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Text('$value', style: AppText.numberSmall),
          IconButton(
            onPressed: value < max ? () => onChange(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}