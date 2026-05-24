import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Student student;
  final AppSettings settings;
  final ValueChanged<Student>? onStudentUpdated;

  const ProfileScreen({
    super.key,
    required this.student,
    this.settings = AppSettings.fallback,
    this.onStudentUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Student _student;
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _fullNameController = TextEditingController(text: _student.fullName);
    _usernameController = TextEditingController(text: _student.username);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.id != widget.student.id ||
        oldWidget.student.fullName != widget.student.fullName ||
        oldWidget.student.username != widget.student.username) {
      _student = widget.student;
      _fullNameController.text = _student.fullName;
      _usernameController.text = _student.username;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();

    if (fullName.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name and username are required')),
      );
      return;
    }

    setState(() => _savingProfile = true);

    try {
      final res = await ApiClient().updateProfile(
        fullName: fullName,
        username: username,
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final updated = Student.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );

      if (!mounted) return;
      setState(() => _student = updated);
      widget.onStudentUpdated?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile')),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _showPasswordSheet() async {
    if (_student.role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin passwords cannot be changed from student app'),
        ),
      );
      return;
    }

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StudentColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final current = currentController.text;
              final next = newController.text;
              final confirm = confirmController.text;

              if (current.isEmpty || next.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all password fields')),
                );
                return;
              }

              if (next != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
                return;
              }

              setSheetState(() => saving = true);
              try {
                await ApiClient().updatePassword(
                  currentPassword: current,
                  newPassword: next,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not update password')),
                );
              } finally {
                if (context.mounted) setSheetState(() => saving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StudentSectionHeader(
                    title: 'Change password',
                    subtitle: 'Use a strong password for your account.',
                    icon: Icons.lock_reset_rounded,
                  ),
                  const SizedBox(height: 16),
                  _darkField(
                    controller: currentController,
                    label: 'Current password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  _darkField(
                    controller: newController,
                    label: 'New password',
                    icon: Icons.password_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  _darkField(
                    controller: confirmController,
                    label: 'Confirm new password',
                    icon: Icons.verified_user_outlined,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving ? null : submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: StudentColors.green,
                        foregroundColor: StudentColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(saving ? 'Saving...' : 'Update password'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
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
              'Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeroCard(),
            const SizedBox(height: 20),
            _buildEditProfileCard(),
            const SizedBox(height: 20),
            _buildAccountCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: studentCardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: StudentColors.blue.withOpacity(0.16),
            child: Text(
              _student.fullName.isNotEmpty
                  ? _student.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: StudentColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _student.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${_student.username}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: StudentColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: StudentColors.green.withOpacity(0.14),
                    border: Border.all(
                      color: StudentColors.green.withOpacity(0.28),
                    ),
                  ),
                  child: Text(
                    _student.role == 'admin' ? 'Admin account' : 'Active student',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBBF7D0),
                      fontWeight: FontWeight.w700,
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

  Widget _buildEditProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: studentCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudentSectionHeader(
            title: 'Profile details',
            subtitle: 'Keep your student identity updated.',
            icon: Icons.manage_accounts_outlined,
          ),
          const SizedBox(height: 16),
          _darkField(
            controller: _fullNameController,
            label: 'Full name',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          _darkField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _savingProfile ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: StudentColors.green,
                foregroundColor: StudentColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(_savingProfile ? 'Saving...' : 'Save profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: studentCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudentSectionHeader(
            title: 'Account',
            subtitle: 'Security and session controls.',
            icon: Icons.security_rounded,
          ),
          const SizedBox(height: 12),
          _actionTile(
            icon: Icons.lock_reset_rounded,
            label: 'Change password',
            color: StudentColors.blue,
            onTap: _showPasswordSheet,
          ),
          const SizedBox(height: 10),
          _actionTile(
            icon: Icons.logout,
            label: 'Logout',
            color: StudentColors.orange,
            onTap: () {
              ApiClient().setToken(null);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: StudentColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: StudentColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  static Widget _darkField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: StudentColors.muted, fontSize: 13),
        prefixIcon: Icon(icon, color: StudentColors.muted),
        filled: true,
        fillColor: StudentColors.bg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: StudentColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: StudentColors.blue),
        ),
      ),
    );
  }
}
