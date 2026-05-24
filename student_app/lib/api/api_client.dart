import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  String? _token;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        // Use 10.0.2.2 when calling localhost backend from Android emulator
        baseUrl: 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  void setToken(String? token) {
    _token = token;
  }

  String get baseUrl => _dio.options.baseUrl;

  Dio get dio {
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
    return _dio;
  }

  // ---------- Auth ----------

  Future<Response> getPublicSettings() {
    return dio.get('/settings/public');
  }

  Future<Response> login(String username, String password) {
    return dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> register({
    required String fullName,
    required String username,
    required String password,
  }) {
    return dio.post('/auth/register', data: {
      'fullName': fullName,
      'username': username,
      'password': password,
    });
  }

  Future<Response> getMe() {
    return dio.get('/auth/me');
  }

  Future<Response> updateProfile({
    required String fullName,
    required String username,
  }) {
    return dio.put('/auth/me', data: {
      'fullName': fullName,
      'username': username,
    });
  }

  Future<Response> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return dio.put('/auth/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ---------- Courses ----------

  Future<Response> getCourses() {
    // Your backend uses /course/list
    return dio.get('/course/list');
  }

  Future<Response> getCourseById(String id) {
    return dio.get('/course/$id');
  }

  // ---------- Enrollments / Fees ----------

  Future<Response> requestOfflineAdmission({
    required String studentId,
    required String courseId,
    required String address,
    required String teacherName,
    required String phone,
    String? message,
  }) {
    return dio.post('/enrollment', data: {
      'studentId': studentId,
      'courseId': courseId,
      'mode': 'offline',
      'paymentType': 'offline',
      'offlineDetails': {
        'address': address,
        'teacherName': teacherName,
        'phone': phone,
        'message': message ?? '',
      },
    });
  }

  Future<Response> getMyFees(String studentId) {
    return dio.get('/enrollment/my-fees/$studentId');
  }

  Future<Response> getAllProgress(String studentId) {
    return dio.get('/progress/$studentId');
  }

  Future<Response> getCourseProgress(String studentId, String courseId) {
    return dio.get('/progress/$studentId/$courseId');
  }

  Future<Response> updateCourseProgress({
    required String studentId,
    required String courseId,
    required String lessonId,
    required bool completed,
  }) {
    return dio.put('/progress/$studentId/$courseId', data: {
      'lessonId': lessonId,
      'completed': completed,
    });
  }

  // ---------- Generic POST helper ----------

  Future<Response> post(String path, {Map<String, dynamic>? data}) {
    return dio.post(path, data: data);
  }

  // ---------- Live class (global) ----------

  // For dashboard: check if student can see live class card
  Future<Response> getGlobalLiveClass(String studentId) {
    return dio.get('/live-class/student/$studentId');
  }

  Future<Response> getInternalLiveViewerToken(String studentId) {
    return dio.post('/live-class/internal/viewer-token', data: {
      'studentId': studentId,
    });
  }

  Future<Response> getVideos() {
    return dio.get('/video/public');
  }
}
