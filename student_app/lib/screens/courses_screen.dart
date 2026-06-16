import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  final Student student;
  final AppSettings settings;

  const CoursesScreen({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _loading = true;
  String? _error;
  String _query = '';
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final res = await api.getCourses();
      final list = res.data as List<dynamic>;
      final courses =
          list.map((item) => Map<String, dynamic>.from(item as Map)).toList();

      if (!mounted) return;
      setState(() => _courses = courses);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error loading courses');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCourses {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _courses;
    return _courses.where((course) {
      final title = '${course['title'] ?? ''}'.toLowerCase();
      final category = '${course['category'] ?? ''}'.toLowerCase();
      return title.contains(q) || category.contains(q);
    }).toList();
  }

  String? _buildCoverUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${ApiClient().baseUrl}/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
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
              'Courses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                StudentSkeletonCard(height: 112),
                StudentSkeletonCard(),
                StudentSkeletonCard(),
                StudentSkeletonCard(),
              ],
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Courses unavailable',
                      message: _error!,
                      actionLabel: 'Retry',
                      onAction: _loadCourses,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 14),
                      _buildSearch(),
                      const SizedBox(height: 14),
                      if (_filteredCourses.isEmpty)
                        StudentEmptyState(
                          icon: Icons.menu_book_outlined,
                          title: _query.trim().isEmpty
                              ? 'No courses yet'
                              : 'No matching courses',
                          message: _query.trim().isEmpty
                              ? 'New courses will appear here after admin adds them.'
                              : 'Try a different title or category.',
                        )
                      else
                        ..._filteredCourses.map(_buildCourseCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildIntroCard() {
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
                  'Choose your next skill',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Browse live and recorded learning programs built for ${widget.settings.instituteName} students.',
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: StudentColors.blue.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: StudentColors.blue,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) => setState(() => _query = value),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search courses or category',
        hintStyle: const TextStyle(color: StudentColors.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: StudentColors.muted),
        filled: true,
        fillColor: StudentColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: StudentColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: StudentColors.blue),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isPaid = course['isPaid'] == true;
    final price = course['price'] ?? 0;
    final coverUrl = _buildCoverUrl(course['coverImageUrl'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: studentCardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final id = course['_id'] as String?;
          if (id == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => CourseDetailScreen(
                  student: widget.student,
                  courseId: id,
                  settings: widget.settings,
                ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: StudentColors.surface,
                  image: coverUrl != null
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coverUrl == null
                    ? const Icon(
                        Icons.menu_book_rounded,
                        color: StudentColors.blue,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'] ?? 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: StudentColors.muted,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _courseBadge(
                          isPaid ? 'Rs. $price' : 'Free',
                          isPaid ? StudentColors.purple : StudentColors.green,
                        ),
                        if ('${course['category'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              course['category'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _courseBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
