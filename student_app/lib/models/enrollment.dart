class Enrollment {
  final String id;
  final String courseId;
  final String paymentStatus;
  final String status;
  final String mode;
  final String courseTitle;
  final String courseDescription;
  final String? coverImageUrl;
  final String category;
  final num coursePrice;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  Enrollment({
    required this.id,
    required this.courseId,
    required this.paymentStatus,
    required this.status,
    required this.mode,
    required this.courseTitle,
    required this.courseDescription,
    required this.coverImageUrl,
    required this.category,
    required this.coursePrice,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Normalizes the course reference returned by the enrollment API.
  /// The API can return a UUID directly or a populated course object.
  static String courseIdFromValue(Object? value) {
    if (value is Map) {
      return _stringValue(
            value['_id'] ??
                value['id'] ??
                value['courseId'] ??
                value['course_id'],
          ) ??
          '';
    }
    return _stringValue(value) ?? '';
  }

  static String? _stringValue(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    final rawCourse = json['courseId'] ?? json['course_id'];
    final course = rawCourse is Map
        ? Map<String, dynamic>.from(rawCourse)
        : <String, dynamic>{};
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final rawExpiresAt = json['expiresAt'] ?? json['expires_at'];
    final status = _stringValue(
      json['status'] ?? json['enrollmentStatus'] ?? json['enrollment_status'],
    );

    return Enrollment(
      id: _stringValue(json['_id'] ?? json['id']) ?? '',
      courseId: courseIdFromValue(rawCourse),
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      status: status?.toLowerCase() ?? 'pending',
      mode: json['mode'] ?? '',
      courseTitle: course?['title'] ?? 'Course Unavailable',
      courseDescription: course?['description'] ?? '',
      coverImageUrl: course?['coverImageUrl'] as String?,
      category: course?['category'] ?? '',
      coursePrice: course?['price'] ?? 0,
      createdAt: rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt)
          : null,
      expiresAt: rawExpiresAt is String
          ? DateTime.tryParse(rawExpiresAt)
          : null,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isPaid => paymentStatus.toLowerCase() == 'paid' && !isExpired;
}
