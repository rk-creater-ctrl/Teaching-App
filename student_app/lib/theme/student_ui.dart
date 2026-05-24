import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';

class StudentColors {
  static const bg = Color(0xFF020617);
  static const surface = Color(0xFF0B1120);
  static const surfaceSoft = Color(0xFF0F172A);
  static const border = Color(0xFF1F2937);
  static const muted = Color(0xFF9CA3AF);
  static const green = Color(0xFF22C55E);
  static const blue = Color(0xFF38BDF8);
  static const orange = Color(0xFFF97316);
  static const purple = Color(0xFFA855F7);
  static const red = Color(0xFFEF4444);
}

BoxDecoration studentCardDecoration({
  Color borderColor = StudentColors.border,
}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      colors: [StudentColors.surfaceSoft, StudentColors.bg],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: borderColor),
    boxShadow: const [
      BoxShadow(
        color: Colors.black54,
        blurRadius: 16,
        offset: Offset(0, 9),
      ),
    ],
  );
}

class StudentSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const StudentSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: StudentColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (icon != null)
          Icon(
            icon,
            color: StudentColors.muted,
            size: 22,
          ),
      ],
    );
  }
}

class StudentEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StudentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: studentCardDecoration(),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: StudentColors.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: StudentColors.blue),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: StudentColors.muted, fontSize: 12),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: StudentColors.green,
                foregroundColor: StudentColors.bg,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class StudentSkeletonCard extends StatelessWidget {
  final double height;

  const StudentSkeletonCard({super.key, this.height = 92});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: StudentColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudentColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: StudentColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _bar(widthFactor: 0.74),
                  const SizedBox(height: 9),
                  _bar(widthFactor: 0.46),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 11,
        decoration: BoxDecoration(
          color: const Color(0xFF172033),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class StudentProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const StudentProgressBar({
    super.key,
    required this.value,
    this.color = StudentColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: 8,
        backgroundColor: const Color(0xFF172033),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class StudentBrandMark extends StatelessWidget {
  final AppSettings settings;
  final double size;
  final double radius;

  const StudentBrandMark({
    super.key,
    required this.settings,
    this.size = 44,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = settings.resolvedLogoUrl(ApiClient().baseUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: logoUrl == null
            ? const LinearGradient(
                colors: [StudentColors.green, StudentColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: logoUrl == null ? null : StudentColors.surface,
        border: Border.all(color: StudentColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null
          ? const Icon(Icons.school_rounded, color: StudentColors.bg)
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.school_rounded,
                  color: StudentColors.blue,
                );
              },
            ),
    );
  }
}
