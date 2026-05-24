import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/enrollment.dart';
import '../models/learning_module.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';
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
  bool _saving = false;
  String? _error;
  Set<String> _completedLessonIds = {};

  List<CourseLesson> get _lessons => defaultCourseLessons(widget.enrollment);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient().getCourseProgress(
        widget.student.id,
        widget.enrollment.courseId,
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final completed = (data['completedLessonIds'] as List<dynamic>? ?? [])
          .map((item) => '$item')
          .toSet();

      if (!mounted) return;
      setState(() {
        _completedLessonIds = completed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load progress';
        _loading = false;
      });
    }
  }

  Future<void> _toggleLesson(CourseLesson lesson, bool completed) async {
    setState(() {
      _saving = true;
      if (completed) {
        _completedLessonIds.add(lesson.id);
      } else {
        _completedLessonIds.remove(lesson.id);
      }
    });

    try {
      final res = await ApiClient().updateCourseProgress(
        studentId: widget.student.id,
        courseId: widget.enrollment.courseId,
        lessonId: lesson.id,
        completed: completed,
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final completedIds = (data['completedLessonIds'] as List<dynamic>? ?? [])
          .map((item) => '$item')
          .toSet();

      if (!mounted) return;
      setState(() => _completedLessonIds = completedIds);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (completed) {
          _completedLessonIds.remove(lesson.id);
        } else {
          _completedLessonIds.add(lesson.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save progress')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final completedCount = _completedLessonIds.length;
    final totalCount = _lessons.length;
    final progress = progressFor(
      completedCount: completedCount,
      totalCount: totalCount,
    );

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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.sync_problem_rounded,
                      title: 'Progress unavailable',
                      message: _error!,
                      actionLabel: 'Retry',
                      onAction: _loadProgress,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProgress,
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
                      const StudentSectionHeader(
                        title: 'Learning modules',
                        subtitle: 'Tick lessons as you complete them.',
                        icon: Icons.task_alt_rounded,
                      ),
                      const SizedBox(height: 12),
                      if (!enrollment.isPaid) ...[
                        const StudentEmptyState(
                          icon: Icons.hourglass_bottom_rounded,
                          title: 'Admission pending',
                          message:
                              'Modules unlock after your fee request is approved.',
                        ),
                        const SizedBox(height: 12),
                      ],
                      ..._lessons.map((lesson) {
                        final completed = _completedLessonIds.contains(lesson.id);
                        return _LessonTile(
                          lesson: lesson,
                          completed: completed,
                          saving: _saving,
                          enabled: enrollment.isPaid,
                          onChanged: (value) =>
                              _toggleLesson(lesson, value ?? false),
                        );
                      }),
                      const SizedBox(height: 18),
                      _ResourcePanel(
                        onVideos: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VideosScreen(
                                settings: widget.settings,
                              ),
                            ),
                          );
                        },
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
                    _miniBadge('Rs. ${enrollment.coursePrice}', StudentColors.blue),
                    if (enrollment.category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _miniBadge(enrollment.category, StudentColors.purple),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: StudentProgressBar(value: progress),
                    ),
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
                  'Use the video library for extra practice.',
                  style: TextStyle(color: StudentColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onVideos,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
