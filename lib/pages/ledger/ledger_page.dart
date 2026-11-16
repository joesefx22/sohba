import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ledger_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/ribbon_card.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.id;
      if (uid != null) context.read<LedgerProvider>().loadForUser(uid);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >
        _scrollCtrl.position.maxScrollExtent - 400) {
      final uid = context.read<AuthProvider>().user?.id;
      if (uid != null) context.read<LedgerProvider>().loadMore(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LedgerProvider>();

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('سجل رصيدي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: p.loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.goldBright),
              )
            : ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (p.summary != null) _summaryCard(p.summary!),
                  const SizedBox(height: 20),
                  if (p.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'لا توجد معاملات بعد',
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        const Icon(Icons.receipt_long,
                            color: AppColors.goldBright, size: 20),
                        const SizedBox(width: 8),
                        Text('آخر المعاملات', style: AppText.section),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...p.entries.map(_entryCard),
                    if (p.loadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.goldBright),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _summaryCard(Map<String, dynamic> s) {
    final hasanat = (s['total_hasanat'] as num?)?.toInt() ?? 0;
    final sayyiat = (s['total_sayyiat'] as num?)?.toInt() ?? 0;
    final iman = (s['iman'] as num?)?.toDouble() ?? 0;
    return RibbonCard(
      accent: AppColors.gold,
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded,
                  color: AppColors.goldBright, size: 20),
              const SizedBox(width: 8),
              Text('رصيد الإيمان',
                  style: AppText.caption.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                iman.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldBright,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Text('إيمان',
                  style: AppText.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat('حسنات', '$hasanat', AppColors.emerald),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat('سيئات', '$sayyiat', AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _entryCard(LedgerEntry e) {
    final c = e.isCredit ? AppColors.emerald : AppColors.error;
    return RibbonCard(
      accent: c,
      radius: 18,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: .35)),
            ),
            child: Icon(
              e.isCredit ? Icons.add : Icons.remove,
              color: c,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.description,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Row(
                  children: [
                    Text(e.sourceLabelAr,
                        style: AppText.caption.copyWith(fontSize: 11)),
                    if (e.note != null) ...[
                      const SizedBox(width: 6),
                      Text('• ${e.note!}',
                          style: AppText.caption.copyWith(
                              fontSize: 11, color: AppColors.mint)),
                    ],
                  ],
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(e.eventAt),
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${e.isCredit ? '+' : ''}${e.amount}',
            style: TextStyle(
              fontSize: 16,
              color: c,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}