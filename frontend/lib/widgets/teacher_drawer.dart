import 'package:flutter/material.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:frontend/screens/common/coming_soon_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Teacher-specific navigation drawer.
///
/// Displays:
///   • Profile section with personal info from the database
///   • Teacher ID, specialization, department, phone
///   • Navigation links: Dashboard, Profile
///   • Role badge at the bottom
///   • Sign Out action
///
/// All data comes from [userData] — nothing is hardcoded.
// ─────────────────────────────────────────────────────────────────────────────
class TeacherDrawer extends StatelessWidget {
  final Map<String, dynamic> userData;
  final int selectedTab;
  final void Function(int tabIndex) onTabSelected;
  final VoidCallback onLogout;

  const TeacherDrawer({
    super.key,
    required this.userData,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onLogout,
  });

  // ── Data helpers ─────────────────────────────────────────────────────────
  String get _name => userData['name'] ?? userData['username'] ?? 'Teacher';
  String get _roleName => userData['role_name'] ?? 'Teacher';
  String get _initials => _name.isNotEmpty ? _name[0].toUpperCase() : 'T';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D0052), Color(0xFF4A148C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Profile section ───────────────────────────────────────────
              _ProfileSection(
                initials: _initials,
                name: _name,
                roleName: _roleName,
                status: (userData['status'] ?? '').toString(),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.15),
                  height: 1,
                ),
              ),

              const SizedBox(height: 8),

              // ── Navigation items ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  children: [
                    _NavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isActive: selectedTab == 0,
                      onTap: () {
                        Navigator.pop(context);
                        onTabSelected(0);
                      },
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'My Profile',
                      isActive: selectedTab == 1,
                      onTap: () {
                        Navigator.pop(context);
                        onTabSelected(1);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Text(
                        'ACADEMIC',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _NavItem(
                      icon: Icons.assignment_turned_in_rounded,
                      label: 'Course Appeal',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ComingSoonScreen(title: 'Course Appeal'),
                          ),
                        );
                      },
                    ),
                    _NavItem(
                      icon: Icons.notifications_active_rounded,
                      label: 'Coursework Notifications',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ComingSoonScreen(
                              title: 'Coursework Notifications',
                            ),
                          ),
                        );
                      },
                    ),
                    _NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ComingSoonScreen(title: 'Reports'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Role badge ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _roleName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              (userData['status'] ?? '')
                                      .toString()
                                      .toUpperCase() ==
                                  'ACTIVE'
                              ? const Color(0xFF69F0AE)
                              : const Color(0xFFFF5252),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(
                color: Colors.white.withValues(alpha: 0.12),
                height: 1,
                indent: 20,
                endIndent: 20,
              ),

              // ── Sign out ──────────────────────────────────────────────────
              ListTile(
                onTap: onLogout,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Profile section inside the drawer
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileSection extends StatelessWidget {
  final String initials;
  final String name;
  final String roleName;
  final String status;

  const _ProfileSection({
    required this.initials,
    required this.name,
    required this.roleName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // Avatar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teacherBadge,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: status.toUpperCase() == 'ACTIVE'
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: status.toUpperCase() == 'ACTIVE'
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.isEmpty ? 'N/A' : status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Single info row inside the profile box
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
/// Navigation item in the drawer
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isActive ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
