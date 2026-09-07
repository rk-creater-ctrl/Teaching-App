import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/enrollment.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';

class CourseDetailScreen extends StatefulWidget {
  final Student student;
  final String courseId;
  final AppSettings settings;

  const CourseDetailScreen({
    super.key,
    required this.student,
    required this.courseId,
    this.settings = AppSettings.fallback,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _course;
  String? _enrollmentStatus;

  final _addressController = TextEditingController();
  final _aadharController = TextEditingController();
  final _mobileController = TextEditingController();
  final _teacherNameController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _aadharController.dispose();
    _mobileController.dispose();
    _teacherNameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _loading = true;
      _error = null;
      _enrollmentStatus = null;
    });

    try {
      final api = ApiClient();
      final currentUserResponse = await api.getMe();
      final currentUser = Student.fromJson(
        Map<String, dynamic>.from(
          (currentUserResponse.data as Map)['user'] as Map,
        ),
      );
      final responses = await Future.wait([
        api.getCourseById(widget.courseId),
        api.getMyFees(currentUser.id),
      ]);
      final data = responses[0].data as Map<String, dynamic>;
      final enrollmentRows = (responses[1].data as List<dynamic>)
          .whereType<Map>()
          .map((item) => Enrollment.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final currentCourseId = Enrollment.courseIdFromValue(data).isNotEmpty
          ? Enrollment.courseIdFromValue(data)
          : widget.courseId;
      final currentEnrollment = _latestEnrollmentForCourse(
        enrollmentRows,
        currentCourseId,
        data['title'] as String? ?? '',
      );

      if (kDebugMode) {
        debugPrint(
          'Enrollment lookup course raw _id=${data['_id']} '
          'id=${data['id']} widgetCourseId=${widget.courseId}',
        );
        debugPrint(
          'Enrollment lookup normalized courseId=$currentCourseId '
          'rows=${enrollmentRows.length}',
        );
        for (final enrollment in enrollmentRows) {
          debugPrint(
            'Enrollment row courseId=${enrollment.courseId} '
            'status=${enrollment.status}',
          );
        }
        debugPrint(
          'Enrollment match id=${currentEnrollment?.id ?? 'none'} '
          'status=${currentEnrollment?.status ?? 'none'}',
        );
      }

      _course = data;
      _enrollmentStatus = currentEnrollment?.status;
    } catch (e) {
      _error = 'Error loading course';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Enrollment? _latestEnrollmentForCourse(
    List<Enrollment> enrollments,
    String courseId,
    String courseTitle,
  ) {
    final idMatches = enrollments
        .where((enrollment) => enrollment.courseId == courseId)
        .toList();
    if (idMatches.isNotEmpty) return _latestEnrollment(idMatches);

    // Older API responses populate course details without including its ID.
    // Use a title only if it identifies exactly one otherwise-unidentifiable row;
    // do not guess when course titles are duplicated.
    final legacyTitleMatches = enrollments
        .where(
          (enrollment) =>
              enrollment.courseId.isEmpty &&
              courseTitle.isNotEmpty &&
              enrollment.courseTitle == courseTitle,
        )
        .toList();
    if (legacyTitleMatches.length != 1) return null;

    return _latestEnrollment(legacyTitleMatches);
  }

  Enrollment? _latestEnrollment(List<Enrollment> enrollments) {
    return enrollments.fold<Enrollment?>(null, (latest, enrollment) {
      if (latest == null) return enrollment;
      final enrollmentCreatedAt = enrollment.createdAt;
      final latestCreatedAt = latest.createdAt;
      if (enrollmentCreatedAt != null &&
          (latestCreatedAt == null ||
              enrollmentCreatedAt.isAfter(latestCreatedAt))) {
        return enrollment;
      }
      return latest;
    });
  }

  bool get _hasCurrentEnrollment =>
      _enrollmentStatus != null && _enrollmentStatus != 'rejected';

  String get _enrollmentStatusLabel {
    switch (_enrollmentStatus) {
      case 'pending':
        return 'Application Pending';
      case 'active':
        return 'Enrolled';
      case 'completed':
        return 'Course Completed';
      default:
        return 'Apply Again';
    }
  }

  Widget _buildEnrollmentStatusCard() {
    final completed = _enrollmentStatus == 'completed';
    final active = _enrollmentStatus == 'active';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF14532D)
            : active
            ? const Color(0xFF0C4A6E)
            : const Color(0xFF78350F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.workspace_premium_rounded
                : active
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _enrollmentStatusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestOffline() async {
    final address = _addressController.text.trim();
    final aadharNumber = _aadharController.text.replaceAll(RegExp(r'\D'), '');
    final mobileNumber = _mobileController.text.replaceAll(RegExp(r'\D'), '');
    final teacherName = _teacherNameController.text.trim();
    final message = _messageController.text.trim();

    if (address.isEmpty ||
        aadharNumber.length != 12 ||
        mobileNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter address, 12-digit Aadhaar number and 10-digit mobile number.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = ApiClient();
      final res = await api.requestOfflineAdmission(
        courseId: widget.courseId,
        address: address,
        aadharNumber: aadharNumber,
        mobileNumber: mobileNumber,
        teacherName: teacherName,
        message: message,
      );

      final data = res.data as Map<String, dynamic>?;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data?['message'] ?? 'Enrollment request created'),
        ),
      );
      await _loadCourse();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating enrollment request')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _buildCoverUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    // adjust host (10.0.2.2, LAN IP, or domain)
    return '${ApiClient().baseUrl}/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;

    return Scaffold(
      backgroundColor: StudentColors.bg,
      appBar: AppBar(
        backgroundColor: StudentColors.bg,
        elevation: 0,
        title: Row(
          children: [
            StudentBrandMark(settings: widget.settings, size: 32, radius: 10),
            const SizedBox(width: 10),
            const Text(
              'Course detail',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                StudentSkeletonCard(height: 240),
                StudentSkeletonCard(height: 86),
                StudentSkeletonCard(height: 86),
              ],
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: StudentEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Course unavailable',
                  message: _error!,
                  actionLabel: 'Retry',
                  onAction: _loadCourse,
                ),
              ),
            )
          : c == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: StudentEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Course not found',
                  message: 'This course may have been removed.',
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top card with image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF020617)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0xFF1F2937)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 20,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            color: Colors.black,
                            image: c['coverImageUrl'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      _buildCoverUrl(
                                        c['coverImageUrl'] as String,
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: c['coverImageUrl'] == null
                              ? const Center(
                                  child: Icon(
                                    Icons.menu_book_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 48,
                                  ),
                                )
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['title'] ?? 'Untitled course',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                c['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: (c['isPaid'] == true)
                                          ? const Color(0xFF4C1D95)
                                          : const Color(0xFF064E3B),
                                    ),
                                    child: Text(
                                      (c['isPaid'] == true)
                                          ? 'Paid: Rs. ${c['price'] ?? 0}'
                                          : 'Free',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (c['category'] != null &&
                                      (c['category'] as String).isNotEmpty)
                                    Text(
                                      c['category'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_hasCurrentEnrollment) ...[
                    _buildEnrollmentStatusCard(),
                  ] else ...[
                    const Text(
                      'Student registration details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDarkTextField(
                      controller: _addressController,
                      label: 'Student address',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    _buildDarkTextField(
                      controller: _aadharController,
                      label: 'Aadhaar number',
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                    ),
                    const SizedBox(height: 8),
                    _buildDarkTextField(
                      controller: _mobileController,
                      label: 'Mobile number',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                    ),
                    const SizedBox(height: 8),
                    _buildDarkTextField(
                      controller: _teacherNameController,
                      label: "Teacher / reference name (optional)",
                    ),
                    const SizedBox(height: 8),
                    _buildDarkTextField(
                      controller: _messageController,
                      label: 'Message',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: _submitting ? null : _requestOffline,
                        child: Text(
                          _submitting
                              ? 'Submitting...'
                              : _enrollmentStatus == 'rejected'
                              ? 'Apply Again'
                              : 'Request offline admission',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF020617),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF020617),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      ),
    );
  }
}
