import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:frontend/providers/theme_provider.dart';

/// Profile screen that loads all user data directly from the database.
/// Works for both students and teachers — displays relevant fields per role.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.fetchMe();
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _profile = result['profile'] as Map<String, dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load profile.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? _buildError()
          : _buildProfile(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final profile = _profile!;
    final roleId = (profile['role_id'] as num?)?.toInt() ?? 0;
    // Note: Teacher role is 2. Student roles are 1 and 6 based on database schema.
    final isStudent = roleId == 1 || roleId == 6;
    final name = profile['full_name'] ?? profile['username'] ?? 'User';
    final roleName =
        profile['role_name'] ?? (isStudent ? 'Student' : 'Teacher');
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final gradientStart = isStudent
        ? AppColors.primaryDark
        : const Color(0xFF4A148C);
    final gradientEnd = isStudent ? AppColors.primary : const Color(0xFF6A1B9A);

    return Column(
      children: [
        // ── Fixed Centered Header ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (isStudent
                      ? AppColors.success
                      : AppColors.teacherBadge),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Scrollable detail cards ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              children: [
                // 1. Role-specific Information (Moved to top)
                if (isStudent) ...[
                  _buildSection(
                    title: 'Academic Information',
                    icon: Icons.school_rounded,
                    children: [
                      _buildInfoRow(
                        'Student ID',
                        profile['student_id']?.toString() ?? 'N/A',
                        Icons.numbers_rounded,
                      ),
                      _buildInfoRow(
                        'Class Name',
                        profile['class_name']?.toString() ?? 'N/A',
                        Icons.class_rounded,
                      ),
                      _buildInfoRow(
                        'Semester',
                        profile['semester']?.toString() ?? 'N/A',
                        Icons.calendar_month_rounded,
                      ),
                      _buildInfoRow(
                        'Faculty',
                        profile['faculty']?.toString() ?? 'N/A',
                        Icons.account_balance_rounded,
                      ),
                      _buildInfoRow(
                        'Department',
                        profile['department']?.toString() ?? 'N/A',
                        Icons.apartment_rounded,
                      ),
                    ],
                  ),
                ] else ...[
                  _buildSection(
                    title: 'Teaching Information',
                    icon: Icons.school_rounded,
                    children: [
                      _buildInfoRow(
                        'Teacher ID',
                        profile['teacher_id']?.toString() ?? 'N/A',
                        Icons.numbers_rounded,
                      ),
                      _buildInfoRow(
                        'Specialization',
                        profile['specialization']?.toString() ?? 'N/A',
                        Icons.auto_stories_rounded,
                      ),
                      _buildInfoRow(
                        'Department',
                        profile['department']?.toString() ?? 'N/A',
                        Icons.apartment_rounded,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // 2. Account information
                _buildSection(
                  title: 'Account Information',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _buildInfoRow('Full Name', name, Icons.person_rounded),
                    _buildInfoRow(
                      'User ID',
                      profile['user_id']?.toString() ?? 'N/A',
                      Icons.badge_rounded,
                    ),
                    _buildInfoRow(
                      'Username',
                      profile['username'] ?? 'N/A',
                      Icons.alternate_email_rounded,
                    ),
                    _buildInfoRow(
                      'Status',
                      profile['status'] ?? 'N/A',
                      isStudent ? null : Icons.circle,
                      valueColor:
                          (profile['status'] ?? '').toUpperCase() == 'ACTIVE'
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    _buildInfoRow('Role', roleName, Icons.security_rounded),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Settings (Dark Mode)
                _buildSection(
                  title: 'App Settings',
                  icon: Icons.settings_rounded,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: themeProvider.isDarkMode
                            ? Colors.amber
                            : Colors.orange,
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        activeColor: AppColors.primary,
                        onChanged: (val) => themeProvider.toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    IconData? icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData? icon, {
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color:
                  valueColor ?? (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
