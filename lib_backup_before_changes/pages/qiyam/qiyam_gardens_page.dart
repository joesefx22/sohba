import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/prayer_log.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class QiyamGardensPage extends StatefulWidget {
  final bool embedded;
  const QiyamGardensPage({super.key, this.embedded = false});

  @override
  State<QiyamGardensPage> createState() => _QiyamGardensPageState();
}

class _QiyamGardensPageState extends State<QiyamGardensPage> {
  bool _loading = true;
  bool _saving = false;

  // Today's state
  bool _shafWitr = false;
  bool _duaDone = false;
  bool _qiyamPrayed = false;
  bool _duhaPrayed = false;

  // Per-prayer sunnah rakats (0, 2, 4, 6)
  final Map<PrayerName, int> _sunnah = {
    PrayerName.fajr: 0,
    PrayerName.dhuhr: 0,
    PrayerName.asr: 0,
    PrayerName.maghrib: 0,
    PrayerName.isha: 0,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.rpc(
        'get_qiyam_range',
        params: {'p_user_id': userId, 'p_days': 1},
      );
      final today = _dateKey(DateTime.now());
      final row = (res as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((r) => r['date'] == today, orElse: () => {});

      if (row.isNotEmpty) {
        _shafWitr = row['prayed_shaf'] == true && row['prayed_witr'] == true;
        _duaDone = row['dua_done'] == true || (row['dua_count'] ?? 0) > 0;
        _qiyamPrayed = row['qiyam_prayed'] == true ||
            (row['tahajjud_rakat'] ?? 0) > 0;
        _duhaPrayed = row['prayed_duha'] == true;
        _sunnah[PrayerName.fajr] = row['fajr_sunnah'] as int? ?? 0;
        _sunnah[PrayerName.dhuhr] = row['dhuhr_sunnah'] as int? ?? 0;
        _sunnah[PrayerName.asr] = row['asr_sunnah'] as int? ?? 0;
        _sunnah[PrayerName.maghrib] = row['maghrib_sunnah'] as int? ?? 0;
        _sunnah[PrayerName.isha] = row['isha_sunnah'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('QiyamGardens._load: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _saveQiyam({
    bool? shafWitr,
    bool? dua,
    bool? qiyam,
  }) async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.rpc('log_qiyam_garden', params: {
        'p_user_id': userId,
        'p_date': _dateKey(DateTime.now()),
        'p_shaf_witr': shafWitr ?? _shafWitr,
        'p_dua_done': dua ?? _duaDone,
        'p_qiyam_prayed': qiyam ?? _qiyamPrayed,
      });
      setState(() {
        _shafWitr = shafWitr ?? _shafWitr;
        _duaDone = dua ?? _duaDone;
        _qiyamPrayed = qiyam ?? _qiyamPrayed;
      });
      if (mounted) AppSnackbar.success(context, 'تقبّل الله');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'فشل: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveDuha() async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.rpc('log_duha', params: {
        'p_user_id': userId,
        'p_date': _dateKey(DateTime.now()),
      });
      setState(() => _duhaPrayed = true);
      if (mounted) AppSnackbar.success(context, 'تقبّل الله');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'فشل: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSunnah(PrayerName prayer, int rakat) async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.rpc('log_sunnah', params: {
        'p_user_id': userId,
        'p_prayer': prayer.name,
        'p_rakat': rakat,
        'p_date': _dateKey(DateTime.now()),
      });
      setState(() => _sunnah[prayer] = rakat);
      if (mounted) {
        final h = (rakat / 2) * 20;
        AppSnackbar.success(context, '+$h حسنة');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'فشل: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.mint))
        : _buildContent();

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: content),
      );
    }
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('جنان القيام والسنن'),
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
        _gardenHeader('🌙', 'جنة قيام الليل', 'من العشاء للفجر',
            AppColors.rarityEpic),
        const SizedBox(height: 12),
        _qiyamGarden(),
        const SizedBox(height: 20),
        _gardenHeader('☀️', 'جنة صلاة الضحى', 'من الشروق للظهر',
            AppColors.gold),
        const SizedBox(height: 12),
        _duhaGarden(),
        const SizedBox(height: 20),
        _gardenHeader('🕌', 'جنة السنن', 'لكل فرض سننه', AppColors.mint),
        const SizedBox(height: 12),
        _sunnahGarden(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _gardenHeader(String emoji, String title, String subtitle, Color c) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppText.section.copyWith(fontSize: 20, color: c)),
              Text(subtitle, style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qiyamGarden() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _questionRow(
            'هل صليت الشفع والوتر؟',
            '+20 حسنة',
            _shafWitr,
            (v) => _saveQiyam(shafWitr: v),
          ),
          _questionRow(
            'هل دعوت في القيام؟',
            '+10 حسنة',
            _duaDone,
            (v) => _saveQiyam(dua: v),
          ),
          _questionRow(
            'هل صليت القيام؟',
            '+20 حسنة',
            _qiyamPrayed,
            (v) => _saveQiyam(qiyam: v),
          ),
        ],
      ),
    );
  }

  Widget _duhaGarden() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _questionRow(
            'هل صليت الضحى النهاردة؟',
            '+20 حسنة',
            _duhaPrayed,
            (_) => _saveDuha(),
          ),
        ],
      ),
    );
  }

  Widget _sunnahGarden() {
    return Column(
      children: PrayerName.values.map((p) {
        final currentRakat = _sunnah[p] ?? 0;
        final hasanat = (currentRakat / 2) * 20;
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(p.icon, color: AppColors.mint, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('سنن ${p.arabicName}',
                        style: AppText.body
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (hasanat > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('+$hasanat',
                          style: AppText.caption.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [0, 2, 4, 6].map((r) {
                  final selected = currentRakat == r;
                  final label = r == 0 ? 'لم أصلِّ' : '$r ركعة';
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: _saving ? null : () => _saveSunnah(p, r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.emerald.withAlpha(60)
                                : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.emerald
                                  : Colors.white.withAlpha(20),
                            ),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppText.caption.copyWith(
                              fontSize: 11,
                              color: selected
                                  ? AppColors.mint
                                  : AppColors.textSecondary,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _questionRow(
    String question,
    String reward,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
                Text(reward,
                    style: AppText.caption
                        .copyWith(color: AppColors.gold, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _saving ? null : onChanged,
            activeThumbColor: AppColors.emerald,
          ),
        ],
      ),
    );
  }
}