import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/himmah_transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/himmah_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class HimmahPage extends StatefulWidget {
  const HimmahPage({super.key});

  @override
  State<HimmahPage> createState() => _HimmahPageState();
}

class _HimmahPageState extends State<HimmahPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.id;
      if (uid != null) context.read<HimmahProvider>().loadForUser(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HimmahProvider>();

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('الهمّة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.text),
            onPressed: () {
              final uid = context.read<AuthProvider>().user?.id;
              if (uid != null) p.loadForUser(uid);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.emerald,
          onRefresh: () async {
            final uid = context.read<AuthProvider>().user?.id;
            if (uid != null) await p.loadForUser(uid);
          },
          child: p.loading && p.transactions.isEmpty
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.mint),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _balanceCard(p),
                    const SizedBox(height: 16),
                    _infoCard(),
                    const SizedBox(height: 20),
                    _transactionsHeader(p),
                    const SizedBox(height: 8),
                    ...p.transactions.isEmpty
                        ? [_emptyTransactions()]
                        : p.transactions.map(_txCard).toList(),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================
  // BALANCE HERO
  // ============================================

  Widget _balanceCard(HimmahProvider p) {
    return GlassContainer(
      level: GlassLevel.featured,
      accent: AppColors.gold,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.diamond_outlined,
                    color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 12),
              Text('رصيد الهمّة',
                  style: AppText.body.copyWith(
                      color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${p.balance}',
                style: AppText.numberLarge.copyWith(
                  fontSize: 56,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Text('همّة',
                  style: AppText.body.copyWith(
                      color: AppColors.textSecondary, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'الهمّة تكافئك على المواصلة اليومية والإنجازات الكبيرة.',
            style: AppText.caption.copyWith(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ============================================
  // INFO CARD
  // ============================================

  Widget _infoCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.mint, size: 18),
              const SizedBox(width: 8),
              Text('كيف تكسب الهمّة؟',
                  style: AppText.section.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('مواصلة يومية', '1–3 همّة/يوم'),
          _infoRow('وسام 7 أيام', '3 همّة'),
          _infoRow('وسام 30 يومًا', '10 همّة'),
          _infoRow('وسام 100 يوم', '50 همّة'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppText.body.copyWith(fontSize: 13)),
          ),
          Text(value,
              style: AppText.caption.copyWith(
                  color: AppColors.gold, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  Widget _transactionsHeader(HimmahProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text('سجل المعاملات', style: AppText.section),
          const Spacer(),
          if (p.transactions.isNotEmpty)
            Text('${p.transactions.length}',
                style: AppText.caption.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyTransactions() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 42, color: AppColors.textSecondary.withAlpha(120)),
          const SizedBox(height: 12),
          Text('لا توجد معاملات بعد',
              style: AppText.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('ابدأ بمواصلة يومية وستكسب أول همّة',
              style: AppText.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _txCard(HimmahTransaction tx) {
    final positive = tx.isCredit;
    final color = positive ? AppColors.emerald : AppColors.warning;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              positive ? Icons.add : Icons.remove,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.reasonAr,
                    style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(_relativeTime(tx.createdAt),
                    style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${tx.amount}',
            style: AppText.numberSmall.copyWith(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}