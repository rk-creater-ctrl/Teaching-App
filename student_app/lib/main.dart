import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models/app_settings.dart';
import 'models/student.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/session_store.dart';
import 'theme/student_ui.dart';

void main() {
  runApp(const SREduNovaStudentApp());
}

class SREduNovaStudentApp extends StatefulWidget {
  const SREduNovaStudentApp({super.key});

  @override
  State<SREduNovaStudentApp> createState() => _SREduNovaStudentAppState();
}

class _SREduNovaStudentAppState extends State<SREduNovaStudentApp> {
  AppSettings _settings = AppSettings.fallback;
  Student? _student;
  bool _checkingSession = true;

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

  Future<void> _restoreSession() async {
    try {
      final token = await SessionStore.getToken();
      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _checkingSession = false);
        return;
      }

      final api = ApiClient();
      api.setToken(token);

      Student? student = await SessionStore.getStudent();

      try {
        final res = await api.getMe();
        final data = Map<String, dynamic>.from(res.data as Map);
        final userJson = data['user'] as Map?;
        if (userJson == null) throw Exception('Invalid saved session');
        student = Student.fromJson(Map<String, dynamic>.from(userJson));
        await SessionStore.updateStudent(student);
      } catch (_) {
        await SessionStore.clear();
        api.setToken(null);
        student = null;
      }

      if (!mounted) return;
      setState(() {
        _student = student;
        _checkingSession = false;
      });
    } catch (_) {
      await SessionStore.clear();
      ApiClient().setToken(null);
      if (!mounted) return;
      setState(() => _checkingSession = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${_settings.brandName} Student',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: StudentColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: StudentColors.green,
          brightness: Brightness.dark,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: StudentColors.surface,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: _checkingSession
          ? const _SessionSplashScreen()
          : _student != null
              ? MainShell(student: _student!, settings: _settings)
              : LoginScreen(initialSettings: _settings),
    );
  }
}

class _SessionSplashScreen extends StatelessWidget {
  const _SessionSplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: StudentColors.bg,
      body: Center(
        child: CircularProgressIndicator(color: StudentColors.green),
      ),
    );
  }
}
