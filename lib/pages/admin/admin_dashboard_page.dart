import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>();
    final auth = context.watch<AuthProvider>();
    final myMember = group.members.firstWhere(
      (m) => m['user_id'] == auth.user!.id,
      orElse: () => {},
    );
    final isAdmin = myMember['role'] == 'admin';

    if (!isAdmin) {
      return GlassScaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'هذه الصفحة متاحة لمشرف المجموعة فقط',
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _overviewCard(group),
            const SizedBox(height: 16),
            _createGroupButton(context),
            const SizedBox(height: 16),
            _statsCard(group),
            const SizedBox(height: 16),
            _membersList(group),
          ],
        ),
      ),
    );
  }

  // ============================================
  // OVERVIEW
  // ============================================
  Widget _overviewCard(GroupProvider group) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      tintColor: AppColors.gold.withAlpha(50),
      child: Row(
        children: [
          const Icon(Icons.groups, color: AppColors.gold, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.group?['name'] ?? 'المجموعة',
                  style: AppText.section.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.members.length} عضو',
                  style: AppText.caption.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ADMIN CREATE GROUP BUTTON
  // ============================================
  Widget _createGroupButton(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.add_circle_outline,
            color: AppColors.mint, size: 26),
        title: Text(
          'إضافة مجموعة جديدة (أدمن)',
          style: AppText.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        subtitle: Text(
          'إنشاء مجموعة مباشرة في قاعدة البيانات',
          style: AppText.caption,
        ),
        trailing: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        onTap: () => _showCreateGroupDialog(context),
      ),
    );
  }

  // ============================================
  // CREATE GROUP DIALOG
  // ============================================
  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إضافة مجموعة جديدة (أدمن)'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'اسم المجموعة'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'أدخل اسم المجموعة'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration:
                    const InputDecoration(labelText: 'الوصف (اختياري)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final userId =
                  dialogCtx.read<AuthProvider>().user!.id;

              final success =
                  await dialogCtx.read<GroupProvider>().adminCreateGroup(
                        name: nameController.text,
                        description: descController.text.isEmpty
                            ? null
                            : descController.text,
                        userId: userId,
                      );

              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إنشاء المجموعة بنجاح')),
                );
              } else {
                final err = context.read<GroupProvider>().error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'فشل الإنشاء')),
                );
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STATS
  // ============================================
  Widget _statsCard(GroupProvider group) {
    final totalIman = group.members.fold<double>(
      0,
      (s, m) => s + ((m['profiles']?['iman'] ?? 0) as num).toDouble(),
    );
    final avgIman =
        group.members.isEmpty ? 0 : totalIman / group.members.length;
    final activeStreaks = group.members
        .where((m) => ((m['profiles']?['current_streak'] ?? 0) as num) > 0)
        .length;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إحصائيات المجموعة', style: AppText.subtitle),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _stat(
                  'إجمالي الإيمان',
                  totalIman.toStringAsFixed(0),
                  AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(
                  'متوسط الإيمان',
                  avgIman.toStringAsFixed(1),
                  AppColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _stat(
                  'أعضاء نشطون',
                  '$activeStreaks',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat('الحالة', 'نشطة', AppColors.emerald),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.numberSmall.copyWith(
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.label),
        ],
      ),
    );
  }

  // ============================================
  // MEMBERS LIST
  // ============================================
  Widget _membersList(GroupProvider group) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الأعضاء', style: AppText.subtitle),
          const SizedBox(height: 12),
          ...group.members.map((m) {
            final p = m['profiles'] as Map<String, dynamic>?;
            final name = p?['name'] ?? 'عضو';
            final iman = ((p?['iman'] ?? 0) as num).toDouble();
            final role = m['role'] as String?;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.mint.withAlpha(60),
                    child: Text(
                      name.characters.first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                        if (role == 'admin')
                          Text(
                            'مشرف',
                            style: AppText.label.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    iman.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}