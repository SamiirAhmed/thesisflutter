import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/utils/app_colors.dart';

// ── Teacher-specific widgets ─────────────────────────────────────────────────
import 'package:frontend/screens/teacher/teacher_dashboard.dart';
import 'package:frontend/widgets/teacher_drawer.dart';

// ── Student / shared widgets ──────────────────────────────────────────────────
import 'package:frontend/widgets/dashboard_header.dart';
import 'package:frontend/widgets/module_card.dart';
// import 'package:frontend/widgets/hero_banner.dart';

// ── Common screens ────────────────────────────────────────────────────────────
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/common/coming_soon_screen.dart';

/// Root dashboard shell.
///
/// After a successful login the API stores the full user payload in
/// SharedPreferences under the key `user_data`. This shell reads that payload
/// and delegates rendering to the correct role-specific view:
///
///   • role_id == ROLE_TEACHER (7) → [_TeacherShell]
///   • anything else               → [_StudentShell]
///
/// No role or permission value is ever hardcoded — every decision
/// is based on data returned by the Laravel API and stored locally.
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Role IDs from the database — kept in sync with the current system
  static const int _roleTeacher = 2;

  @override
  void initState() {
    super.initState();
    _loadLocalUser();
  }

  Future<void> _loadLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user_data');
    if (!mounted) return;

    if (stored != null) {
      setState(() {
        _userData = jsonDecode(stored) as Map<String, dynamic>;
        _isLoading = false;
      });
      // Verify account status in background
      _verifyStatus();
    } else {
      // No local session — send back to login
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      });
    }
  }

  Future<void> _verifyStatus() async {
    // fetchMe will return success: false if status is not ACTIVE
    final result = await ApiService.fetchMe();
    if (!mounted) return;

    if (result['success'] == false) {
      final msg = (result['message'] ?? '').toString().toLowerCase();
      if (msg.contains('inactive') || msg.contains('unauthorized')) {
        // Log them out and show reason
        await _logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Account status changed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teacherBadge),
        ),
      );
    }

    if (_userData == null) {
      return const SizedBox.shrink(); // redirect handled in initState
    }

    final roleId = (_userData!['role_id'] as num?)?.toInt() ?? 0;

    if (roleId == _roleTeacher) {
      return _TeacherShell(userData: _userData!, onLogout: _logout);
    }

    // Fallback for students and any other allowed role
    final modules =
        (_userData!['modules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return _StudentShell(
      userData: _userData!,
      modules: modules,
      onLogout: _logout,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TEACHER SHELL
// ═════════════════════════════════════════════════════════════════════════════
/// Full scaffold for the teacher role.
///
/// Bottom navigation has two tabs:
///   0 → Dashboard (TeacherDashboard)
///   1 → Profile (ProfileScreen — fetched fresh from the DB)
///
/// Sidebar (TeacherDrawer) shows DB-loaded personal info and the same tabs.
/// Teacher is NOT shown History or any student-only sections.
class _TeacherShell extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Future<void> Function() onLogout;

  const _TeacherShell({required this.userData, required this.onLogout});

  @override
  State<_TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<_TeacherShell> {
  int _selectedTab = 0;

  static const _teacherGradientTop = Color(0xFF3A0066);
  static const _teacherPrimary = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    // Pages for IndexedStack — index matches bottom nav
    final pages = <Widget>[
      TeacherDashboard(userData: widget.userData),
      const ProfileScreen(),
    ];

    return Scaffold(
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : _teacherGradientTop,
        foregroundColor: Colors.white,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'JUST Portal',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Teacher drawer ──────────────────────────────────────────────────
      drawer: TeacherDrawer(
        userData: widget.userData,
        selectedTab: _selectedTab,
        onTabSelected: (i) => setState(() => _selectedTab = i),
        onLogout: widget.onLogout,
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: IndexedStack(index: _selectedTab, children: pages),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: _teacherPrimary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  STUDENT SHELL
// ═════════════════════════════════════════════════════════════════════════════
/// Full scaffold for the student role.
///
/// Bottom navigation has three tabs:
///   0 → Dashboard (_StudentDashboardHome)
///   1 → History (ComingSoonScreen)
///   2 → Profile (ProfileScreen)
class _StudentShell extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> modules;
  final Future<void> Function() onLogout;

  const _StudentShell({
    required this.userData,
    required this.modules,
    required this.onLogout,
  });

  @override
  State<_StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<_StudentShell> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final name =
        widget.userData['name'] ?? widget.userData['username'] ?? 'User';
    final roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    final roleName =
        widget.userData['role_name'] ?? (roleId == 1 ? 'Student' : 'User');

    final pages = <Widget>[
      _StudentDashboardHome(userData: widget.userData),
      const ComingSoonScreen(title: 'History'),
      const ProfileScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surface
            : AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'JUST Portal',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),

      drawer: _StudentDrawer(
        name: name,
        roleName: roleName,
        roleId: roleId,
        userData: widget.userData,
        modules: widget.modules,
        selectedTab: _selectedTab,
        onTabSelected: (i) => setState(() => _selectedTab = i),
        onLogout: widget.onLogout,
      ),

      body: IndexedStack(index: _selectedTab, children: pages),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Student dashboard home content
// ─────────────────────────────────────────────────────────────────────────────
class _StudentDashboardHome extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _StudentDashboardHome({required this.userData});

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] ?? userData['username'] ?? 'User';
    final roleId = (userData['role_id'] as num?)?.toInt() ?? 0;
    final roleName = userData['role_name'] ?? 'Student';
    final modules =
        (userData['modules'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          DashboardHeader(name: name, roleName: roleName, roleId: roleId),

          // Student academic summary
          if (roleId == 6 && userData['student_summary'] != null)
            _StudentSummaryCard(
              summary: Map<String, dynamic>.from(
                userData['student_summary'] as Map,
              ),
            ),

          // Modules from database
          _StudentModulesSection(
            modules: modules,
            onModuleTap: (title) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ComingSoonScreen(title: title)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Student academic summary card
// ─────────────────────────────────────────────────────────────────────────────
class _StudentSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _StudentSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Academic Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow(
                    Icons.badge_rounded,
                    'Student ID',
                    summary['student_id']?.toString() ?? 'N/A',
                  ),
                  _infoRow(
                    Icons.account_balance_rounded,
                    'Faculty',
                    summary['faculty']?.toString() ?? 'N/A',
                  ),
                  _infoRow(
                    Icons.apartment_rounded,
                    'Department',
                    summary['department']?.toString() ?? 'N/A',
                  ),
                  _infoRow(
                    Icons.class_rounded,
                    'Class',
                    summary['class_name']?.toString() ?? 'N/A',
                  ),
                  _infoRow(
                    Icons.calendar_month_rounded,
                    'Semester',
                    summary['semester']?.toString() ?? 'N/A',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Student module categories section
// ─────────────────────────────────────────────────────────────────────────────
class _StudentModulesSection extends StatelessWidget {
  final List<Map<String, dynamic>> modules;
  final void Function(String title) onModuleTap;

  const _StudentModulesSection({
    required this.modules,
    required this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            modules.isEmpty
                ? 'No categories assigned yet.'
                : 'Submit and track your appeals & complaints',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          if (modules.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (_, i) {
                final m = modules[i];
                final key = m['key'] as String? ?? '';
                final title = m['title'] as String? ?? 'Module';
                return ModuleCard(
                  title: title,
                  moduleKey: key,
                  onTap: () => onModuleTap(title),
                );
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(30),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No categories assigned.\nPlease contact the administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
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
/// Student navigation drawer
// ─────────────────────────────────────────────────────────────────────────────
class _StudentDrawer extends StatelessWidget {
  final String name;
  final String roleName;
  final int roleId;
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> modules;
  final int selectedTab;
  final void Function(int) onTabSelected;
  final Future<void> Function() onLogout;

  const _StudentDrawer({
    required this.name,
    required this.roleName,
    required this.roleId,
    required this.userData,
    required this.modules,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: AppColors.primaryDark,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const SizedBox(width: 36, height: 36),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JUST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (userData['status'] ?? '')
                                    .toString()
                                    .toUpperCase() ==
                                'ACTIVE'
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              (userData['status'] ?? '')
                                      .toString()
                                      .toUpperCase() ==
                                  'ACTIVE'
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color:
                                (userData['status'] ?? '')
                                        .toString()
                                        .toUpperCase() ==
                                    'ACTIVE'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (userData['status'] ?? 'N/A')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white.withOpacity(0.15), height: 1),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _drawerItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isActive: selectedTab == 0,
                  onTap: () {
                    Navigator.pop(context);
                    onTabSelected(0);
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.history_rounded,
                  label: 'History',
                  isActive: selectedTab == 1,
                  onTap: () {
                    Navigator.pop(context);
                    onTabSelected(1);
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'My Profile',
                  isActive: selectedTab == 2,
                  onTap: () {
                    Navigator.pop(context);
                    onTabSelected(2);
                  },
                ),

                if (modules.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Text(
                      'CATEGORIES',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...modules.map((m) {
                    final title = m['title'] ?? 'Module';
                    final key = m['key'] ?? '';
                    IconData icon = Icons.description_rounded;
                    if (key.contains('exam')) icon = Icons.quiz_rounded;
                    if (key.contains('class')) icon = Icons.class_rounded;
                    if (key.contains('env')) icon = Icons.apartment_rounded;

                    return _drawerItem(
                      context,
                      icon: icon,
                      label: title,
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComingSoonScreen(title: title),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    roleName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          ListTile(
            onTap: onLogout,
            leading: const Icon(Icons.logout_rounded, color: Colors.white60),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    IconData? icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
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
