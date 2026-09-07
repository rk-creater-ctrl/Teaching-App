import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'student_auth_token';
  static const _studentKey = 'student_user';

  static String _dismissedNotificationsKey(String studentId) {
    return 'dismissed_notifications_$studentId';
  }

  static Future<void> clearStoredAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_studentKey);
  }

  static Future<void> clear({String? studentId}) async {
    final prefs = await SharedPreferences.getInstance();
    await clearStoredAuthentication();
    if (studentId != null && studentId.trim().isNotEmpty) {
      await prefs.remove(_dismissedNotificationsKey(studentId));
    }
  }

  static Future<Set<String>> getDismissedNotificationIds(
    String studentId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_dismissedNotificationsKey(studentId)) ?? [])
        .toSet();
  }

  static Future<void> dismissNotifications({
    required String studentId,
    required Iterable<String> notificationIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dismissedNotificationsKey(studentId);
    final current = (prefs.getStringList(key) ?? []).toSet();
    current.addAll(notificationIds.where((id) => id.trim().isNotEmpty));
    await prefs.setStringList(key, current.toList());
  }
}
