import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/enrollment.dart';
import '../models/learning_module.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';
import 'live_class_screen.dart';
import 'videos_screen.dart';

class EnrolledCourseDetailScreen extends StatefulWidget {
  final Student student;
  final AppSettings settings;
  final Enrollment enrollment;

  const EnrolledCourseDetailScreen({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
    required this.enrollment,
  });

  @override
  State<EnrolledCourseDetailScreen> createState() =>
      _EnrolledCourseDetailScreenState();
}

class _EnrolledCourseDetailScreenState
    extends State<EnrolledCourseDetailScreen> {
  bool _loading = true;
  int _completedVideoCount = 0;
  int _totalVideoCount = 0;
  String? _courseId;
  bool _hasCourseLive = false;
  String? _courseLiveTitle;
  String? _courseLiveStatus;
  String? _courseLiveScheduledAt;
  bool _courseLiveJoinable = false;

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
  }

  Future<String?> _resolveCourseId() async {
    final enrollmentCourseId = widget.enrollment.courseId.trim();
    if (enrollmentCourseId.isNotEmpty) return enrollmentCourseId;

    final res = await ApiClient().getCourses();
    final matchingIds = (res.data as List<dynamic>)
        .whereType<Map>()
        .map((course) => Map<String, dynamic>.from(course))
        .where((course) => course['title'] == widget.enrollment.courseTitle)
        .map((course) => '${course['_id'] ?? course['id'] ?? ''}'.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    return matchingIds.length == 1 ? matchingIds.single : null;
  }

  Future<void> _loadCourseContent() async {
    setState(() {
      _loading = true;
    });

    try {
      final courseId = await _resolveCourseId();
      if (!mounted) return;
      if (courseId == null) {
        setState(() => _loading = false);
        return;
      }

      _courseId = courseId;
      var completedCount = _completedVideoCount;
      var totalCount = _totalVideoCount;
      var hasCourseLive = false;
      String? courseLiveTitle;
      String? courseLiveStatus;
      String? courseLiveScheduledAt;
      var courseLiveJoinable = false;

      try {
        final res = await ApiClient().getCourseProgress(
          widget.student.id,
          courseId,
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        completedCount = (data['completedCount'] as num?)?.toInt() ?? 0;
        totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // Progress is optional for the course video experience.
      }

      try {
        final res = await ApiClient().getCourseLiveClass(courseId);
        final data = Map<String, dynamic>.from(res.data as Map);
        hasCourseLive = data['hasLive'] == true;
        courseLiveTitle = data['title'] as String?;
        courseLiveStatus = data['status'] as String?;
        courseLiveScheduledAt = data['scheduledAt'] as String?;
        courseLiveJoinable =
            hasCourseLive &&
            courseLiveStatus == 'live' &&
            data['activeMode'] == 'internal' &&
            data['internalLiveActive'] == true;
      } catch (_) {
        // The course page remains usable when optional live metadata fails.
      }

      if (!mounted) return;
      setState(() {
        _completedVideoCount = completedCount;
        _totalVideoCount = totalCount;
        _hasCourseLive = hasCourseLive;
        _courseLiveTitle = courseLiveTitle;
        _courseLiveStatus = courseLiveStatus;
        _courseLiveScheduledAt = courseLiveScheduledAt;
        _courseLiveJoinable = courseLiveJoinable;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Progress is optional for the course video experience. Keep the course
      // and its authorized Videos action available if this request fails.
      setState(() => _loading = false);
    }
  }

  String? _coverUrl() {
    final raw = widget.enrollment.coverImageUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${ApiClient().baseUrl}/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final enrollment = widget.enrollment;
    final completedCount = _completedVideoCount;
    final totalCount = _totalVideoCount;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Scaffold(
      backgroundColor: StudentColors.bg,
      appBar: AppBar(
        backgroundColor: StudentColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            StudentBrandMark(settings: widget.settings, size: 32, radius: 10),
            const SizedBox(width: 10),
            const Text(
              'My course',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                StudentSkeletonCard(height: 170),
                StudentSkeletonCard(height: 92),
                StudentSkeletonCard(height: 92),
                StudentSkeletonCard(height: 92),
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadCourseContent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CourseHero(
                    enrollment: enrollment,
                    coverUrl: _coverUrl(),
                    progress: progress,
                    completedCount: completedCount,
                    totalCount: totalCount,
                  ),
                  const SizedBox(height: 18),
                  if (_courseId != null)
                    _ResourcePanel(
                      onVideos: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VideosScreen(
                              settings: widget.settings,
                              student: widget.student,
                              courseId: _courseId,
                              courseTitle: enrollment.courseTitle,
                              onCourseProgressChanged: _loadCourseContent,
                            ),
                          ),
                        );
                        if (mounted) await _loadCourseContent();
                      },
                    )
                  else
                    const StudentEmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'Course videos unavailable',
                      message: 'This course could not be identified safely.',
                    ),
                  const SizedBox(height: 12),
                  _CourseLivePanel(
                    title: _courseLiveTitle,
                    status: _courseLiveStatus,
                    scheduledAt: _courseLiveScheduledAt,
                    hasLive: _hasCourseLive,
                    joinable: _courseLiveJoinable,
                    onJoin: _courseId == null || !_courseLiveJoinable
                        ? null
                        : () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LiveClassScreen(
                                  student: widget.student,
                                  settings: widget.settings,
                                  courseId: _courseId,
                                ),
                              ),
                            );
                            if (mounted) await _loadCourseContent();
                          },
                  ),
                  const SizedBox(height: 18),
                  const StudentSectionHeader(
                    title: 'Course progress',
                    subtitle: 'Progress is based on completed course videos.',
                    icon: Icons.task_alt_rounded,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$completedCount of $totalCount videos completed',
                    style: const TextStyle(
                      color: StudentColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  final Enrollment enrollment;
  final String? coverUrl;
  final double progress;
  final int completedCount;
  final int totalCount;

  const _CourseHero({
    required this.enrollment,
    required this.coverUrl,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: studentCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              color: Colors.black,
              image: coverUrl == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage(coverUrl!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: coverUrl == null
                ? const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: StudentColors.blue,
                      size: 46,
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
                  enrollment.courseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (enrollment.courseDescription.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    enrollment.courseDescription,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudentColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniBadge(
                      enrollment.isPaid ? 'Active' : 'Pending',
                      enrollment.isPaid
                          ? StudentColors.green
                          : StudentColors.orange,
                    ),
                    const SizedBox(width: 8),
                    _miniBadge(
                      'Rs. ${enrollment.coursePrice}',
                      StudentColors.blue,
                    ),
                    if (enrollment.category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _miniBadge(enrollment.category, StudentColors.purple),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: StudentProgressBar(value: progress)),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedCount of $totalCount modules complete',
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final CourseLesson lesson;
  final bool completed;
  final bool saving;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _LessonTile({
    required this.lesson,
    required this.completed,
    required this.saving,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudentColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? StudentColors.green : StudentColors.border,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: completed,
            activeColor: StudentColors.green,
            onChanged: saving || !enabled ? null : onChanged,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.subtitle,
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            lesson.duration,
            style: const TextStyle(color: StudentColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ResourcePanel extends StatelessWidget {
  final VoidCallback onVideos;

  const _ResourcePanel({required this.onVideos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: studentCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: StudentColors.blue.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.ondemand_video_rounded,
              color: StudentColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Watch videos included with this course.',
                  style: TextStyle(color: StudentColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onVideos,
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CourseLivePanel extends StatelessWidget {
  final String? title;
  final String? status;
  final String? scheduledAt;
  final bool hasLive;
  final bool joinable;
  final VoidCallback? onJoin;

  const _CourseLivePanel({
    required this.title,
    required this.status,
    required this.scheduledAt,
    required this.hasLive,
    required this.joinable,
    required this.onJoin,
  });

  String get _statusText {
    if (!hasLive) return 'No live class available';
    if (joinable) return 'Live now';
    if (status == 'ended') return 'This live class has ended';
    final scheduled = DateTime.tryParse(scheduledAt ?? '');
    if (scheduled != null) {
      final local = scheduled.toLocal();
      return 'Scheduled for ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return 'Not started yet';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: studentCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (joinable ? StudentColors.red : StudentColors.purple)
                  .withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              joinable ? Icons.wifi_tethering_rounded : Icons.live_tv_rounded,
              color: joinable ? StudentColors.red : StudentColors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title?.trim().isNotEmpty == true ? title! : 'Live class',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (joinable)
            TextButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Join'),
            ),
        ],
      ),
    );
  }
}
