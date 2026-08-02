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

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    final course = json['courseId'] as Map<String, dynamic>?;
    final rawCourseId = course?['_id'] ?? json['courseId'];
    final rawCreatedAt = json['createdAt'];
    final rawExpiresAt = json['expiresAt'];

    return Enrollment(
      id: json['_id'] ?? '',
      courseId: rawCourseId is String ? rawCourseId : '',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      status: json['status'] ?? 'pending',
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
