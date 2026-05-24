import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import 'dashboard_screen.dart';
import 'courses_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final Student student;
  final AppSettings settings;

  const MainShell({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late Student _student;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _settings = widget.settings;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient().getPublicSettings();
      final settings = AppSettings.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );

      if (!mounted) return;
      setState(() => _settings = settings);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        student: _student,
        settings: _settings,
        onOpenCourses: () => setState(() => _index = 1),
      ),
      CoursesScreen(student: _student, settings: _settings),
      ProfileScreen(
        student: _student,
        settings: _settings,
        onStudentUpdated: (student) => setState(() => _student = student),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: pages[_index],
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          backgroundColor: Color(0xFF020617),
          indicatorColor: Color(0xFF0F172A),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
            ),
          ),
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: Color(0xFF9CA3AF)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF22C55E)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: Color(0xFF38BDF8)),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFFF97316)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
