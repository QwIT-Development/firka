import 'package:live_activities/live_activities.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/extensions.dart';

class LiveActivityService {
  static const String _activityType = 'FirkaLessonActivity';
  static final LiveActivities _liveActivities = LiveActivities();

  /// Initialize live activities
  static Future<void> initialize() async {
    try {
      await _liveActivities.init();
    } catch (e) {
      print('Failed to initialize live activities: $e');
    }
  }

  /// Create a live activity for the current/next lesson
  static Future<String?> createLessonActivity({
    required Lesson currentLesson,
    Lesson? nextLesson,
    required DateTime now,
  }) async {
    try {
      final activityId = await _liveActivities.createActivity(
        _activityType,
        _buildActivityData(
          currentLesson: currentLesson,
          nextLesson: nextLesson,
          now: now,
        ),
      );
      
      print('Created live activity with ID: $activityId');
      return activityId;
    } catch (e) {
      print('Failed to create live activity: $e');
      return null;
    }
  }

  /// Update an existing live activity
  static Future<void> updateLessonActivity({
    required String activityId,
    required Lesson currentLesson,
    Lesson? nextLesson,
    required DateTime now,
  }) async {
    try {
      await _liveActivities.updateActivity(
        activityId,
        _buildActivityData(
          currentLesson: currentLesson,
          nextLesson: nextLesson,
          now: now,
        ),
      );
      
      print('Updated live activity: $activityId');
    } catch (e) {
      print('Failed to update live activity: $e');
    }
  }

  /// End a live activity
  static Future<void> endActivity(String activityId) async {
    try {
      await _liveActivities.endActivity(activityId);
      print('Ended live activity: $activityId');
    } catch (e) {
      print('Failed to end live activity: $e');
    }
  }

  /// Get all active live activities
  static Future<List<String>> getActiveActivities() async {
    try {
      return await _liveActivities.getAllActivitiesIds();
    } catch (e) {
      print('Failed to get active activities: $e');
      return [];
    }
  }

  /// End all active activities
  static Future<void> endAllActivities() async {
    try {
      final activeIds = await getActiveActivities();
      for (final id in activeIds) {
        await endActivity(id);
      }
    } catch (e) {
      print('Failed to end all activities: $e');
    }
  }

  /// Build activity data for the widget
  static Map<String, dynamic> _buildActivityData({
    required Lesson currentLesson,
    Lesson? nextLesson,
    required DateTime now,
  }) {
    final currentProgress = _calculateLessonProgress(currentLesson, now);
    final isLessonActive = now.isAfter(currentLesson.start) && now.isBefore(currentLesson.end);
    
    return {
      'currentLesson': {
        'subject': currentLesson.subject,
        'teacher': currentLesson.teacher,
        'classroom': currentLesson.classroom,
        'startTime': _formatTime(currentLesson.start),
        'endTime': _formatTime(currentLesson.end),
        'progress': currentProgress,
        'isActive': isLessonActive,
      },
      if (nextLesson != null)
        'nextLesson': {
          'subject': nextLesson.subject,
          'teacher': nextLesson.teacher,
          'classroom': nextLesson.classroom,
          'startTime': _formatTime(nextLesson.start),
          'endTime': _formatTime(nextLesson.end),
        },
      'timestamp': now.millisecondsSinceEpoch,
    };
  }

  /// Calculate lesson progress as a percentage (0.0 to 1.0)
  static double _calculateLessonProgress(Lesson lesson, DateTime now) {
    if (now.isBefore(lesson.start)) return 0.0;
    if (now.isAfter(lesson.end)) return 1.0;
    
    final totalDuration = lesson.end.difference(lesson.start).inMilliseconds;
    final elapsed = now.difference(lesson.start).inMilliseconds;
    
    return elapsed / totalDuration;
  }

  /// Format time as HH:mm
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Check if live activities are available on this device
  static Future<bool> areActivitiesEnabled() async {
    try {
      return await _liveActivities.areActivitiesEnabled();
    } catch (e) {
      print('Failed to check if activities are enabled: $e');
      return false;
    }
  }

  /// Get the current lesson from a list of lessons
  static Lesson? getCurrentLesson(List<Lesson> lessons, DateTime now) {
    try {
      return lessons.firstWhere(
        (lesson) => now.isAfter(lesson.start) && now.isBefore(lesson.end),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the next lesson from a list of lessons
  static Lesson? getNextLesson(List<Lesson> lessons, DateTime now) {
    try {
      final futureLessons = lessons
          .where((lesson) => lesson.start.isAfter(now))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      
      return futureLessons.isNotEmpty ? futureLessons.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Get the upcoming lesson (current if active, otherwise next)
  static Lesson? getUpcomingLesson(List<Lesson> lessons, DateTime now) {
    final current = getCurrentLesson(lessons, now);
    if (current != null) return current;
    
    return getNextLesson(lessons, now);
  }
}
