import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';
import 'main_shell.dart';

enum AuthMode { login, register }

class LoginScreen extends StatefulWidget {
  final AppSettings initialSettings;

  const LoginScreen({
    super.key,
    this.initialSettings = AppSettings.fallback,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  AppSettings _settings = AppSettings.fallback;
  bool _loading = false;
  String? _error;

  bool get _isRegistering => _mode == AuthMode.register;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _loadSettings();
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSettings.appName != widget.initialSettings.appName ||
        oldWidget.initialSettings.logoUrl != widget.initialSettings.logoUrl) {
      _settings = widget.initialSettings;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient().getPublicSettings();
      final settings = AppSettings.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );

      if (!mounted) return;
      setState(() => _settings = settings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = AppSettings.fallback);
    }
  }

  Future<void> _handleAuth() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Username and password are required.');
      return;
    }

    if (_isRegistering) {
      if (fullName.isEmpty) {
        setState(() => _error = 'Full name is required.');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _error = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      var res = _isRegistering
          ? await api.register(
              fullName: fullName,
              username: username,
              password: password,
            )
          : await api.login(username, password);

      var data = Map<String, dynamic>.from(res.data as Map);

      if (_isRegistering && data['token'] == null) {
        res = await api.login(username, password);
        data = Map<String, dynamic>.from(res.data as Map);
      }

      final token = data['token'] as String?;
      final userJson = data['user'] as Map?;

      if (token == null || userJson == null) {
        throw Exception('Invalid auth response');
      }

      api.setToken(token);
      final student = Student.fromJson(Map<String, dynamic>.from(userJson));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(
            student: student,
            settings: _settings,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = _isRegistering
            ? 'Sign up failed. Try another username.'
            : 'Login failed. Check username/password.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                color: const Color(0xFF0B1120),
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFF1F2937)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StudentBrandMark(settings: _settings),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _settings.appName,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isRegistering
                                      ? 'Create student account'
                                      : 'Student Portal',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildFeatureStrip(),
                      const SizedBox(height: 18),
                      SegmentedButton<AuthMode>(
                        segments: const [
                          ButtonSegment<AuthMode>(
                            value: AuthMode.login,
                            label: Text('Login'),
                            icon: Icon(Icons.login_rounded),
                          ),
                          ButtonSegment<AuthMode>(
                            value: AuthMode.register,
                            label: Text('Sign up'),
                            icon: Icon(Icons.person_add_alt_1_rounded),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (values) => _setMode(values.first),
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? const Color(0xFF020617)
                                : const Color(0xFFE5E7EB),
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF020617),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF450A0A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF7F1D1D)),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFFECACA)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_isRegistering) ...[
                        _buildField(
                          controller: _fullNameController,
                          label: 'Full name',
                          icon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: _isRegistering
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isRegistering && !_loading) _handleAuth();
                        },
                      ),
                      if (_isRegistering) ...[
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _confirmPasswordController,
                          label: 'Confirm password',
                          icon: Icons.verified_user_outlined,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_loading) _handleAuth();
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: _loading ? null : _handleAuth,
                          child: Text(
                            _loading
                                ? (_isRegistering
                                    ? 'Creating account...'
                                    : 'Signing in...')
                                : (_isRegistering ? 'Sign up' : 'Login'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF020617),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () => _setMode(
                                    _isRegistering
                                        ? AuthMode.login
                                        : AuthMode.register,
                                  ),
                          child: Text(
                            _isRegistering
                                ? 'Already have an account? Login'
                                : 'New student? Sign up',
                            style: const TextStyle(color: Color(0xFF38BDF8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: const Color(0xFF020617),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      ),
    );
  }

  Widget _buildFeatureStrip() {
    final items = [
      (Icons.live_tv_rounded, 'Live classes', StudentColors.red),
      (Icons.auto_graph_rounded, 'Progress', StudentColors.green),
      (Icons.ondemand_video_rounded, 'Videos', StudentColors.blue),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: item.$3.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: item.$3.withOpacity(0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$1, size: 15, color: item.$3),
              const SizedBox(width: 6),
              Text(
                item.$2,
                style: TextStyle(
                  color: item.$3,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
