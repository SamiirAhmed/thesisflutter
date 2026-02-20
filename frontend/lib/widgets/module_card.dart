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
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.title,
    required this.moduleKey,
    required this.onTap,
  });

  static IconData _iconFor(String key) {
    switch (key.toLowerCase()) {
      case 'exam_appeal':
      case 'exam appeal':
        return Icons.quiz_rounded;
      case 'class_issue':
      case 'class issue':
        return Icons.class_rounded;
      case 'campus_environment':
      case 'campus environment':
        return Icons.apartment_rounded;
      case 'appeals':
        return Icons.assignment_turned_in_rounded;
      case 'complaints':
        return Icons.rate_review_rounded;
      case 'results':
        return Icons.analytics_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.moduleColor(moduleKey);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(moduleKey), color: color, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
