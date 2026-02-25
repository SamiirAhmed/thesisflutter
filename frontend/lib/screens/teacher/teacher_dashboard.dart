import 'package:flutter/material.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:frontend/screens/common/coming_soon_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Teacher-specific dashboard body.
///
/// Displays:
///   • Teacher ID & Role chip at the top
///   • Three module cards sourced from the database
///     (Course Appeal, Coursework Notifications, Report)
///
/// All data comes from [userData] which is loaded from the API at login.
/// Nothing is hardcoded — cards are driven by [modules] from the DB.
// ─────────────────────────────────────────────────────────────────────────────
class TeacherDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Future<void> Function() onRefresh;

  const TeacherDashboard({
    super.key,
    required this.userData,
    required this.onRefresh,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Map<String, dynamic> userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  @override
  void didUpdateWidget(TeacherDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userData != widget.userData) {
      setState(() => userData = widget.userData);
    }
  }

  Future<void> _loadData() async {
    await widget.onRefresh();
  }

  // Convenience getters
  String get _name => userData['name'] ?? userData['username'] ?? 'Teacher';
  String get _roleName => userData['role_name'] ?? 'Teacher';

  Map<String, dynamic> get _teacherProfile =>
      (userData['teacher_profile'] as Map<String, dynamic>?) ?? {};

  String get _teacherId => _teacherProfile['teacher_id']?.toString() ?? '—';

  List<Map<String, dynamic>> get _modules =>
      (userData['modules'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      displacement: 20,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Collapsible Hero Header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _TeacherHeroHeader(
              name: _name,
              roleName: _roleName,
              teacherId: _teacherId,
              status: (userData['status'] ?? '').toString(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Dashboard Modules Section ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _modules.isEmpty
                        ? 'No sections assigned yet.'
                        : 'Manage your course appeals and reports',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Module Grid ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: _modules.isEmpty
                ? SliverToBoxAdapter(child: _EmptyModulesPlaceholder())
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final module = _modules[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TeacherModuleCard(
                          module: module,
                          isWide: true,
                          onTap: (title) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComingSoonScreen(title: title),
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: _modules.length),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Hero gradient header showing teacher identity information
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherHeroHeader extends StatelessWidget {
  final String name;
  final String roleName;
  final String teacherId;
  final String status;

  const _TeacherHeroHeader({
    required this.name,
    required this.roleName,
    required this.teacherId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A0066), Color(0xFF6A1B9A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x556A1B9A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            right: -24,
            top: -24,
            child: CircleAvatar(
              radius: 68,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -16,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withOpacity(0.04),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + greeting row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Identity info chips row — display: Teacher ID & Role (Teacher)
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.badge_rounded,
                      label: 'Teacher ID:',
                      value: teacherId,
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.verified_user_rounded,
                      label: 'Role:',
                      value: roleName,
                    ),
                    const SizedBox(width: 10),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.toUpperCase() == 'ACTIVE'
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status.toUpperCase() == 'ACTIVE'
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: status.toUpperCase() == 'ACTIVE'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Small pill chip used inside the hero header
// ─────────────────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 5),
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
          ],
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Individual teacher module card — clean, modern, clickable.
/// [isWide] renders a horizontal layout for the featured card.
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherModuleCard extends StatefulWidget {
  final Map<String, dynamic> module;
  final bool isWide;
  final void Function(String title) onTap;

  const _TeacherModuleCard({
    required this.module,
    required this.isWide,
    required this.onTap,
  });

  @override
  State<_TeacherModuleCard> createState() => _TeacherModuleCardState();
}

class _TeacherModuleCardState extends State<_TeacherModuleCard> {
  bool _pressed = false;

  static IconData _iconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'course_appeal':
      case 'appeals':
        return Icons.assignment_turned_in_rounded;
      case 'notifications':
      case 'coursework_notifications':
      case 'notification':
        return Icons.notifications_active_rounded;
      case 'report':
      case 'reports':
        return Icons.bar_chart_rounded;
      case 'complaints':
        return Icons.rate_review_rounded;
      case 'grading':
        return Icons.grade_rounded;
      case 'schedule':
        return Icons.calendar_today_rounded;
      case 'attendance':
        return Icons.how_to_reg_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  static Color _colorForKey(String key) {
    switch (key.toLowerCase()) {
      case 'course_appeal':
      case 'appeals':
        return const Color(0xFF3949AB); // indigo
      case 'notifications':
      case 'coursework_notifications':
      case 'notification':
        return const Color(0xFF00897B); // teal
      case 'report':
      case 'reports':
        return const Color(0xFF5E35B1); // deep purple
      default:
        return const Color(0xFF6A1B9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.module['key'] as String? ?? '';
    final title = widget.module['title'] as String? ?? 'Module';
    final description = widget.module['description'] as String? ?? '';
    final color = _colorForKey(key);
    final icon = _iconForKey(key);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap(title);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.isWide ? 110 : null,
          padding: widget.isWide
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
              : const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(_pressed ? 0.22 : 0.12),
                blurRadius: _pressed ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: _pressed ? color.withOpacity(0.3) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: widget.isWide
              ? _buildWideContent(title, description, color, icon)
              : _buildSquareContent(title, description, color, icon),
        ),
      ),
    );
  }

  Widget _buildWideContent(
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: color.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildSquareContent(
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Shown when no modules are assigned from the database
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyModulesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.layers_outlined,
              size: 52,
              color: AppColors.teacherBadge,
            ),
            SizedBox(height: 14),
            Text(
              'No sections assigned.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact the administrator\nto set up your access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
