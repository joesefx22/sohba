import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_lesson.dart';

class DailyLessonService {
  DailyLessonService._();

  static Future<DailyLesson?> todayLesson() async {
    final today = DateTime.now();
    final res = await Supabase.instance.client
        .from('daily_lessons')
        .select()
        .lte('publish_date',
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}')
        .order('publish_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return DailyLesson.fromJson(res);
  }

  static Future<void> markListened({
    required String userId,
    required String lessonId,
  }) async {
    await Supabase.instance.client.from('user_lesson_logs').upsert({
      'user_id': userId,
      'lesson_id': lessonId,
      'listened_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<bool> hasListened({
    required String userId,
    required String lessonId,
  }) async {
    final res = await Supabase.instance.client
        .from('user_lesson_logs')
        .select('lesson_id')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .maybeSingle();
    return res != null;
  }
}