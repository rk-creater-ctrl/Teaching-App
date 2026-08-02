import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';

class SessionStore {
  static const _tokenKey = 'student_auth_token';
  static const _studentKey = 'student_user';

  static String _dismissedNotificationsKey(String studentId) {
    return 'dismissed_notifications_$studentId';
  }

  static Future<void> saveSession({
    required String token,
    required Student student,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_studentKey, jsonEncode(student.toJson()));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Student?> getStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_studentKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return Student.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateStudent(Student student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studentKey, jsonEncode(student.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_studentKey);
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
