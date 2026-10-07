import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gid = context.read<GroupProvider>().group?['id'] as String?;
      if (gid != null) context.read<ChallengeProvider>().loadForGroup(gid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ChallengeProvider>();
    final auth = context.watch<AuthProvider>();

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('التحديات'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreate(context, auth.user!.id),
          ),
        ],
      ),
      body: SafeArea(
        child: p.loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mint),
              )
            : p.challenges.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد تحديات — ابدأ واحدًا مع إخوانك',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: p.challenges.map((c) {
                      final participants = p.participantsOf(c.id);
                      final mine = participants
                          .where((pp) => pp.userId == auth.user!.id)
                          .firstOrNull;
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title,
                                style: AppText.section.copyWith(
                                  fontSize: 18,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              '${c.targetDays} يوم • ${participants.length} مشارك',
                              style: AppText.caption,
                            ),
                            const SizedBox(height: 12),
                            if (mine != null) ...[
                              LinearProgressIndicator(
                                value: (mine.progress / c.targetDays)
                                    .clamp(0.0, 1.0),
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.mint),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mine.completed
                                    ? 'أكملت التحدي ✓'
                                    : '${mine.progress}/${c.targetDays}',
                                style: AppText.caption.copyWith(
                                  color: mine.completed
                                      ? AppColors.emerald
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ] else
                              OutlinedButton(
                                onPressed: () => p.join(
                                  challengeId: c.id,
                                  userId: auth.user!.id,
                                  groupId: c.groupId,
                                ),
                                child: const Text('انضمام'),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }

  Future<void> _showCreate(BuildContext context, String userId) async {
    final group = context.read<GroupProvider>().group;
    if (group == null) return;

    final titleCtrl = TextEditingController();
    int days = 7;
    String type = 'fajr_streak';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تحدي جديد',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان التحدي',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: 'النوع', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'fajr_streak', child: Text('الفجر جماعة')),
                  DropdownMenuItem(
                      value: 'all_prayers', child: Text('كل الصلوات')),
                ],
                onChanged: (v) =>
                    setSheet(() => type = v ?? 'fajr_streak'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('عدد الأيام: '),
                  Expanded(
                    child: Slider(
                      value: days.toDouble(),
                      min: 3,
                      max: 30,
                      divisions: 27,
                      label: '$days',
                      onChanged: (v) => setSheet(() => days = v.round()),
                    ),
                  ),
                  Text('$days'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await context.read<ChallengeProvider>().create(
                          groupId: group['id'] as String,
                          userId: userId,
                          title: titleCtrl.text.trim(),
                          type: type,
                          targetDays: days,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('إنشاء'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}