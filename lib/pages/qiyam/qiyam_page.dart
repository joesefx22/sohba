import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../repositories/qiyam_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/ribbon_card.dart';

class QiyamPage extends StatefulWidget {
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
            child: CircularProgressIndicator(color: AppColors.goldBright),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        RibbonCard(
          accent: AppColors.iman,
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.iman.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.nightlight_round,
                        color: AppColors.iman, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'تسجيل اليوم',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _switchTile(
                title: 'صليت الشفع',
                value: _shaf,
                onChanged: (v) => setState(() => _shaf = v),
              ),
              _switchTile(
                title: 'صليت الوتر',
                value: _witr,
                onChanged: (v) => setState(() => _witr = v),
              ),
              _switchTile(
                title: 'صليت الضحى',
                value: _duha,
                onChanged: (v) => setState(() => _duha = v),
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.gold.withValues(alpha: .22)),
              const SizedBox(height: 8),
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
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.goldBright,
            activeTrackColor: AppColors.gold.withValues(alpha: .4),
          ),
        ],
      ),
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
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: value > 0 ? () => onChange(value - 1) : null,
            icon: const Icon(Icons.remove),
            color: AppColors.goldBright,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.goldBright,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChange(value + 1) : null,
            icon: const Icon(Icons.add),
            color: AppColors.goldBright,
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