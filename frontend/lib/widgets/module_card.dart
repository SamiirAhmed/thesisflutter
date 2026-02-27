import 'package:flutter/material.dart';
import 'package:frontend/utils/app_colors.dart';

/// A card that represents a single module/category loaded from the database.
///
/// Used in the student dashboard grid. For the teacher dashboard, the
/// dedicated [_TeacherModuleCard] inside `teacher_dashboard.dart` is used.
///
/// Tapping navigates to the module screen (or shows Coming Soon).
class ModuleCard extends StatelessWidget {
  final String title;
  final String moduleKey;
  final String? iconName;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.title,
    required this.moduleKey,
    this.iconName,
    required this.onTap,
  });

  static IconData _iconFor(String key, String? iconName) {
    if (iconName != null && iconName.isNotEmpty) {
      switch (iconName.toLowerCase()) {
        case 'assignment_rounded':
          return Icons.assignment_rounded;
        case 'apartment_rounded':
          return Icons.apartment_rounded;
        case 'home_work_rounded':
          return Icons.home_work_rounded;
        case 'analytics_rounded':
          return Icons.analytics_rounded;
        case 'quiz_rounded':
          return Icons.quiz_rounded;
        case 'assignment_turned_in_rounded':
          return Icons.assignment_turned_in_rounded;
      }
    }

    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('exam')) return Icons.biotech_rounded;
    if (lowerKey.contains('class')) return Icons.payments_rounded;
    if (lowerKey.contains('enviroment')) return Icons.architecture_rounded;
    if (lowerKey.contains('report')) return Icons.terminal_rounded;

    return Icons.grid_view_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.moduleColor(moduleKey);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconFor(moduleKey, iconName),
              color: color,
              size: 58, // Larger icon to match the design
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
