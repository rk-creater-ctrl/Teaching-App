import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/enrollment.dart';
import '../models/learning_module.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';
import 'enrolled_course_detail_screen.dart';
import 'live_class_screen.dart';
import 'videos_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Student student;
  final AppSettings settings;
  final VoidCallback? onOpenCourses;

  const DashboardScreen({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
    this.onOpenCourses,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  List<Enrollment> _enrollments = [];
  Map<String, Set<String>> _completedByCourse = {};

  bool _checkingLive = true;
  bool _hasLiveAccess = false;
  bool _hasLive = false;
  String? _liveTitle;
  String _liveMode = 'internal';
  bool _internalLiveActive = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadDashboard(),
      _loadLiveClass(),
    ]);
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final feeRes = await api.getMyFees(widget.student.id);
      final list = feeRes.data as List<dynamic>;
      final enrollments = list
          .map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
          .toList();

      final progressRes = await api.getAllProgress(widget.student.id);
      final progressList = progressRes.data as List<dynamic>;
      final progressByCourse = <String, Set<String>>{};
      for (final item in progressList) {
        final data = Map<String, dynamic>.from(item as Map);
        final courseId = '${data['courseId']}';
        final completed = (data['completedLessonIds'] as List<dynamic>? ?? [])
            .map((id) => '$id')
            .toSet();
        progressByCourse[courseId] = completed;
      }

      if (!mounted) return;
      setState(() {
        _enrollments = enrollments;
        _completedByCourse = progressByCourse;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading dashboard data';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLiveClass() async {
    try {
      final api = ApiClient();
      final res = await api.getGlobalLiveClass(widget.student.id);
      final data = res.data as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _checkingLive = false;
        _hasLiveAccess = data['hasAccess'] == true;
        _hasLive = data['hasLive'] == true;
        _liveTitle = data['title'] as String?;
        _liveMode = data['activeMode'] as String? ?? 'internal';
        _internalLiveActive = data['internalLiveActive'] == true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingLive = false;
        _hasLiveAccess = false;
        _hasLive = false;
      });
    }
  }

  int _completedCountFor(Enrollment enrollment) {
    return _completedByCourse[enrollment.courseId]?.length ?? 0;
  }

  double _progressForEnrollment(Enrollment enrollment) {
    final total = defaultCourseLessons(enrollment).length;
    return progressFor(
      completedCount: _completedCountFor(enrollment),
      totalCount: total,
    );
  }

  double get _averageProgress {
    final active = _enrollments.where((item) => item.isPaid).toList();
    if (active.isEmpty) return 0;
    final total = active.fold<double>(
      0,
      (sum, item) => sum + _progressForEnrollment(item),
    );
    return total / active.length;
  }

  @override
  Widget build(BuildContext context) {
    final active = _enrollments.where((e) => e.isPaid).length;
    final pending = _enrollments.where((e) => !e.isPaid).length;

    return Scaffold(
      backgroundColor: StudentColors.bg,
      appBar: _buildHeader(),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.sync_problem_rounded,
                      title: 'Dashboard unavailable',
                      message: _error!,
                      actionLabel: 'Retry',
                      onAction: _loadAll,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 16),
                      _buildNotificationPanel(pending),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildStatCard(
                            'Active courses',
                            active.toString(),
                            icon: Icons.play_circle_fill_rounded,
                            color: StudentColors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Pending fees',
                            pending.toString(),
                            icon: Icons.receipt_long_rounded,
                            color: StudentColors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Progress',
                            '${(_averageProgress * 100).round()}%',
                            icon: Icons.trending_up_rounded,
                            color: StudentColors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Videos',
                            'Learn',
                            icon: Icons.ondemand_video_rounded,
                            color: StudentColors.purple,
                            onTap: _openVideos,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildLiveClassSection(),
                      const SizedBox(height: 22),
                      const StudentSectionHeader(
                        title: 'My learning',
                        subtitle: 'Track modules for your enrolled courses.',
                        icon: Icons.auto_graph_rounded,
                      ),
                      const SizedBox(height: 12),
                      if (_enrollments.isEmpty)
                        StudentEmptyState(
                          icon: Icons.school_outlined,
                          title: 'No enrollments yet',
                          message: 'Browse courses and request admission to begin.',
                          actionLabel: 'Open courses',
                          onAction: widget.onOpenCourses,
                        )
                      else
                        ..._enrollments.map(_buildEnrollmentProgressCard),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: StudentColors.bg,
      elevation: 0,
      toolbarHeight: 74,
      titleSpacing: 16,
      title: Row(
        children: [
          StudentBrandMark(settings: widget.settings, size: 42),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.settings.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hi, ${widget.student.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: _showNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.white),
                if (_notificationCount > 0)
                  Positioned(
                    right: -1,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: StudentColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int get _notificationCount {
    var count = 0;
    if (_liveIsJoinable) count++;
    count += _enrollments.where((item) => !item.isPaid).length;
    return count;
  }

  bool get _liveIsJoinable {
    return !_checkingLive &&
        _hasLiveAccess &&
        _hasLive &&
        _liveMode == 'internal' &&
        _internalLiveActive;
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        StudentSkeletonCard(height: 132),
        StudentSkeletonCard(height: 96),
        StudentSkeletonCard(height: 96),
        StudentSkeletonCard(height: 96),
        StudentSkeletonCard(height: 96),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: studentCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your learning desk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.student.username,
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                StudentProgressBar(value: _averageProgress),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: StudentColors.green.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: StudentColors.green,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPanel(int pending) {
    final items = <Widget>[];

    if (_liveIsJoinable) {
      items.add(
        _AlertTile(
          icon: Icons.live_tv_rounded,
          color: StudentColors.red,
          title: _liveTitle ?? 'Live class',
          subtitle: 'Teacher is live now. Join from your app.',
          actionLabel: 'Join',
          onTap: _openLiveClass,
        ),
      );
    }

    if (pending > 0) {
      items.add(
        _AlertTile(
          icon: Icons.receipt_long_rounded,
          color: StudentColors.orange,
          title: '$pending fee ${pending == 1 ? 'request' : 'requests'} pending',
          subtitle: 'Admin approval is needed before live class access opens.',
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _AlertTile(
          icon: Icons.check_circle_rounded,
          color: StudentColors.green,
          title: 'All caught up',
          subtitle: 'No pending fee or live-class alerts right now.',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: studentCardDecoration(),
      child: Column(children: items),
    );
  }

  Widget _buildLiveClassSection() {
    if (!_liveIsJoinable) return const SizedBox.shrink();

    return Container(
      decoration: studentCardDecoration(borderColor: StudentColors.red),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: StudentColors.red,
          child: Icon(Icons.live_tv_rounded, color: Colors.white),
        ),
        title: Text(
          _liveTitle ?? 'Live class',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Live class available now',
          style: TextStyle(color: StudentColors.muted, fontSize: 12),
        ),
        trailing: FilledButton.icon(
          onPressed: _openLiveClass,
          style: FilledButton.styleFrom(
            backgroundColor: StudentColors.green,
            foregroundColor: StudentColors.bg,
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Join'),
        ),
      ),
    );
  }

  Widget _buildEnrollmentProgressCard(Enrollment enrollment) {
    final progress = _progressForEnrollment(enrollment);
    final completed = _completedCountFor(enrollment);
    final total = defaultCourseLessons(enrollment).length;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EnrolledCourseDetailScreen(
              student: widget.student,
              settings: widget.settings,
              enrollment: enrollment,
            ),
          ),
        );
        _loadDashboard();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: studentCardDecoration(
          borderColor: enrollment.isPaid ? StudentColors.border : StudentColors.orange,
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: enrollment.isPaid
                      ? const Color(0xFF022C22)
                      : const Color(0xFF451A03),
                  child: Icon(
                    enrollment.isPaid
                        ? Icons.verified_rounded
                        : Icons.hourglass_bottom_rounded,
                    color: enrollment.isPaid
                        ? StudentColors.green
                        : StudentColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.courseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        enrollment.isPaid
                            ? '$completed of $total modules completed'
                            : 'Fee pending - Rs. ${enrollment.coursePrice}',
                        style: const TextStyle(
                          color: StudentColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 12),
            StudentProgressBar(
              value: progress,
              color: enrollment.isPaid ? StudentColors.green : StudentColors.orange,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: StudentColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final pending = _enrollments.where((item) => !item.isPaid).length;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StudentSectionHeader(
                title: 'Notifications',
                subtitle: 'Live class and fee updates.',
                icon: Icons.notifications_active_outlined,
              ),
              const SizedBox(height: 14),
              _buildNotificationPanel(pending),
            ],
          ),
        );
      },
    );
  }

  void _openLiveClass() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveClassScreen(
          student: widget.student,
          settings: widget.settings,
        ),
      ),
    );
  }

  void _openVideos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideosScreen(settings: widget.settings),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value, {
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.all(15),
      decoration: studentCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: StudentColors.muted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: content,
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
