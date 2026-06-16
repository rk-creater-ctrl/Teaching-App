import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models/app_settings.dart';
import 'screens/login_screen.dart';
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

  @override
  void initState() {
    super.initState();
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
      home: LoginScreen(initialSettings: _settings),
    );
  }
}
