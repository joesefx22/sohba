import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_alert.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class AdminAlertsPage extends StatefulWidget {
  final String groupId;
  const AdminAlertsPage({super.key, required this.groupId});

  @override
  State<AdminAlertsPage> createState() => _AdminAlertsPageState();
}

class _AdminAlertsPageState extends State<AdminAlertsPage> {
  List<AdminAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('admin_alerts')
          .select()
          .eq('group_id', widget.groupId)
          .eq('is_resolved', false)
          .order('created_at', ascending: false)
          .limit(50);
      _alerts = (res as List)
          .map((e) => AdminAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('AdminAlerts.load: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resolve(AdminAlert a) async {
    await Supabase.instance.client.from('admin_alerts').update({
      'is_resolved': true,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', a.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('يحتاج متابعة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mint),
              )
            : _alerts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'لا توجد حالات تحتاج متابعة',
                        style: AppText.caption,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) {
                      final a = _alerts[i];
                      final color = a.severity == 'high'
                          ? AppColors.error
                          : a.severity == 'normal'
                              ? AppColors.warning
                              : AppColors.mint;
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withAlpha(40),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.warning_amber_rounded,
                                  color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: AppText.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(a.message, style: AppText.caption),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _resolve(a),
                              child: const Text('تمت'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}