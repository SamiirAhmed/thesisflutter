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
    final bool isInactive =
        _errorMessage != null &&
        (_errorMessage!.toLowerCase().contains('inactive') ||
            _errorMessage!.toLowerCase().contains('status'));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isInactive
                    ? Colors.orange.withOpacity(0.1)
                    : AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInactive
                    ? Icons.lock_person_rounded
                    : Icons.error_outline_rounded,
                size: 64,
                color: isInactive ? Colors.orange : AppColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isInactive ? 'Account Restricted' : 'Error Occurred',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (isInactive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ApiService.logout().then((_) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Return to Login',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (profile['status'] ?? '').toString().toUpperCase() ==
                          'ACTIVE'
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        (profile['status'] ?? '').toString().toUpperCase() ==
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
                      size: 8,
                      color:
                          (profile['status'] ?? '').toString().toUpperCase() ==
                              'ACTIVE'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (profile['status'] ?? 'UNKNOWN').toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Scrollable detail cards with pull-to-refresh ─────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProfile,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                children: [
                  // Summary Cards (ID, HEMIS, Class, Semester)
                  if (isStudent) ...[
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _buildSummaryCard(
                          'Student ID',
                          profile['student_id']?.toString() ?? 'N/A',
                          Icons.person_rounded,
                          Colors.green.shade50,
                          Colors.green,
                        ),
                        _buildSummaryCard(
                          'NIRA',
                          profile['nira']?.toString() ?? 'N/A',
                          Icons.check_box_rounded,
                          Colors.blue.shade50,
                          Colors.blue,
                        ),
                        _buildSummaryCard(
                          'Class',
                          profile['class_name']?.toString() ?? 'N/A',
                          Icons.bookmark_rounded,
                          Colors.orange.shade50,
                          Colors.orange,
                        ),
                        _buildSummaryCard(
                          'Semester',
                          profile['semester']?.toString() ?? 'N/A',
                          Icons.calendar_month_rounded,
                          Colors.purple.shade50,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 1. Role-specific Information (Moved to top)
                  if (isStudent) ...[
                    _buildSection(
                      title: 'Academic Information',
                      icon: Icons.school_rounded,
                      children: [
                        _buildInfoRow(
                          'Campus',
                          profile['campus_name']?.toString() ?? 'N/A',
                          Icons.apartment_rounded,
                        ),
                        _buildInfoRow(
                          'Shift',
                          profile['shift']?.toString() ?? 'N/A',
                          Icons.schedule_rounded,
                        ),
                        _buildInfoRow(
                          'Entry Time',
                          profile['entry_time']?.toString() ?? 'N/A',
                          Icons.access_time_rounded,
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

                  // 2. Educational Background
                  _buildSection(
                    title: 'Educational Background',
                    icon: Icons.assignment_rounded,
                    children: [
                      _buildInfoRow(
                        'School',
                        profile['previous_school']?.toString() ?? 'N/A',
                        Icons.school_rounded,
                      ),
                      _buildInfoRow(
                        'Graduation Year',
                        profile['grad_year']?.toString() ?? 'N/A',
                        Icons.calendar_today_rounded,
                      ),
                      _buildInfoRow(
                        'Grade',
                        profile['grade']?.toString() ?? 'N/A',
                        Icons.star_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Personal Information (Replaces Account Information)
                  _buildSection(
                    title: 'Personal Information',
                    icon: Icons.person_rounded,
                    children: [
                      _buildInfoRow(
                        'Gender',
                        profile['gender']?.toString() ?? 'N/A',
                        Icons.person_outline_rounded,
                      ),
                      _buildInfoRow(
                        'Place of Birth',
                        profile['pob']?.toString() ?? 'N/A',
                        Icons.location_on_rounded,
                      ),
                      _buildInfoRow(
                        'Address',
                        profile['address']?.toString() ?? 'N/A',
                        Icons.home_rounded,
                      ),
                      if (isStudent)
                        _buildInfoRow(
                          "Mother's Name",
                          profile['mother_name']?.toString() ?? 'N/A',
                          Icons.group_rounded,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Contact Information
                  _buildSection(
                    title: 'Contact Information',
                    icon: Icons.phone_rounded,
                    children: [
                      _buildInfoRow(
                        'Phone',
                        profile['phone']?.toString() ?? 'N/A',
                        Icons.phone_iphone_rounded,
                      ),
                      _buildInfoRow(
                        'Email',
                        profile['email']?.toString() ?? 'N/A',
                        Icons.mail_outline_rounded,
                      ),
                      _buildInfoRow(
                        'Emergency Contact',
                        profile['emergency_contact']?.toString() ?? 'N/A',
                        Icons.star_rounded,
                      ),
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
                  const SizedBox(height: 24),

                  // 4. Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ApiService.logout().then((_) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (route) => false);
                      }),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
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
