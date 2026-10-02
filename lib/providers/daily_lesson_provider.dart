import 'package:flutter/foundation.dart';

import '../models/daily_lesson.dart';
import '../services/daily_lesson_service.dart';

class DailyLessonProvider extends ChangeNotifier {
  DailyLesson? _lesson;
  bool _listened = false;
  bool _loading = false;

  DailyLesson? get lesson => _lesson;
  bool get listened => _listened;
  bool get loading => _loading;

  Future<void> loadForUser(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      _lesson = await DailyLessonService.todayLesson();
      if (_lesson != null) {
        _listened = await DailyLessonService.hasListened(
          userId: userId,
          lessonId: _lesson!.id,
        );
      }
    } catch (e) {
      debugPrint('DailyLessonProvider.loadForUser: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markListened(String userId) async {
    if (_lesson == null) return;
    await DailyLessonService.markListened(
      userId: userId,
      lessonId: _lesson!.id,
    );
    _listened = true;
    notifyListeners();
  }
}