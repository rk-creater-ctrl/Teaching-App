import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models/app_settings.dart';
import 'screens/login_screen.dart';
import 'theme/student_ui.dart';

void main() {
  runApp(const TechJaguarStudentApp());
}

class TechJaguarStudentApp extends StatefulWidget {
  const TechJaguarStudentApp({super.key});

  @override
  State<TechJaguarStudentApp> createState() => _TechJaguarStudentAppState();
}

class _TechJaguarStudentAppState extends State<TechJaguarStudentApp> {
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
      title: '${_settings.appName} Student',
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
