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

  Future<void> _startUnauthenticated() async {
    ApiClient().setToken(null);
    await SessionStore.clearStoredAuthentication();
    if (!mounted) return;
    setState(() => _checkingSession = false);
  }

  Future<void> _onAuthenticated(String token, Student student) async {
    ApiClient().setToken(token);
    if (!mounted) return;
    setState(() => _student = student);
  }

  Future<void> _logout() async {
    await SessionStore.clear(studentId: _student?.id);
    ApiClient().setToken(null);
    if (!mounted) return;
    setState(() => _student = null);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startUnauthenticated();
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
          ? MainShell(
              key: ValueKey(_student!.id),
              student: _student!,
              settings: _settings,
              onLogout: _logout,
            )
          : LoginScreen(
              initialSettings: _settings,
              onAuthenticated: _onAuthenticated,
            ),
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
