import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

// ── MODELS ───────────────────────────────────────────────────────────────────

class ClassIssueType {
  final int catNo;
  final String catName;

  ClassIssueType({required this.catNo, required this.catName});

  factory ClassIssueType.fromJson(Map<String, dynamic> json) {
    return ClassIssueType(catNo: json['cat_no'], catName: json['cat_name']);
  }
}

class ClassroomIssue {
  final int id;
  final String issueName;
  final String description;
  final String status;
  final String className;
  final String submittedAt;

  ClassroomIssue({
    required this.id,
    required this.issueName,
    required this.description,
    required this.status,
    required this.className,
    required this.submittedAt,
  });

  factory ClassroomIssue.fromJson(Map<String, dynamic> json) {
    return ClassroomIssue(
      id: int.tryParse(json['id'].toString()) ?? 0,
      issueName: json['issue_name']?.toString() ?? 'Unknown Issue',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      className: json['class_name']?.toString() ?? 'Unknown Class',
      submittedAt: json['submitted_at']?.toString() ?? '',
    );
  }
}

class IssueTracking {
  final int id;
  final String newStatus;
  final String? note;
  final String changedDate;

  IssueTracking({
    required this.id,
    required this.newStatus,
    this.note,
    required this.changedDate,
  });

  factory IssueTracking.fromJson(Map<String, dynamic> json) {
    return IssueTracking(
      id: int.tryParse(json['cit_no'].toString()) ?? 0,
      newStatus: json['new_status']?.toString() ?? 'Unknown',
      note: json['note']?.toString(),
      changedDate: json['changed_date']?.toString() ?? '',
    );
  }
}

// ── SERVICE ──────────────────────────────────────────────────────────────────

class ClassIssueService {
  static Future<String> _getApiUrl(String path) async {
    final baseUrl = await ApiService.getBaseUrl();
    // Using Laravel API structure: /api/v1/class-issues/...
    return '$baseUrl/api/v1/class-issues$path';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final userId = prefs.getString('auth_user_id') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-USER-ID': userId,
    };
  }

  static Future<List<ClassIssueType>> getIssueTypes() async {
    try {
      final url = await _getApiUrl('/types');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List data = decoded['data'];
          return data.map((item) => ClassIssueType.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMyClasses() async {
    try {
      final url = await _getApiUrl('/my-classes');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitIssue(
    int catNo,
    String description,
    int? clsNo,
    String? title,
  ) async {
    try {
      final url = await _getApiUrl('/submit');
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'cat_no': catNo,
          'title': title,
          'description': description,
          'cls_no': clsNo,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<List<ClassroomIssue>> getMyIssues() async {
    try {
      final url = await _getApiUrl('/my-issues');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List data = decoded['data'];
          return data.map((item) => ClassroomIssue.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<IssueTracking>> getTracking(int complaintId) async {
    try {
      final url = await _getApiUrl('/tracking/$complaintId');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List data = decoded['data'];
          return data.map((item) => IssueTracking.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// ── SCREENS ──────────────────────────────────────────────────────────────────

class ClassIssueListScreen extends StatefulWidget {
  const ClassIssueListScreen({super.key});
  @override
  State<ClassIssueListScreen> createState() => _ClassIssueListScreenState();
}

class _ClassIssueListScreenState extends State<ClassIssueListScreen> {
  List<ClassroomIssue> _issues = [];
  bool _isLoading = true;
  bool _isLeader = false;
  String _selectedStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final userData = await ApiService.getLocalUserData();
    _isLeader = userData?['is_leader'] ?? false;
    await _refreshIssues();
  }

  Future<void> _refreshIssues() async {
    try {
      final issues = await ClassIssueService.getMyIssues();
      if (mounted) {
        setState(() {
          _issues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF0F1012)
        : const Color(0xFFF9FAFF);
    final Color surfaceColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Issue Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _buildProfessionalFilterBar(isDark, surfaceColor, textColor),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshIssues,
                    color: AppColors.primary,
                    child: _buildIssuesList(isDark, surfaceColor, textColor),
                  ),
                ),
              ],
            ),
      floatingActionButton: _isLeader ? _buildProfessionalFAB() : null,
    );
  }

  Widget _buildProfessionalFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitIssueScreen()),
          );
          if (result == true) _refreshIssues();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: const Text(
          'REPORT INQUIRY',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildProfessionalFilterBar(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          _buildFilterChip(
            'Pending',
            Icons.timer_outlined,
            color: Colors.orange,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildFilterChip(
            'Resolved',
            Icons.check_circle_outline_rounded,
            color: Colors.green,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildFilterChip(
            'Rejected',
            Icons.highlight_off_rounded,
            color: Colors.redAccent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon, {
    required Color color,
    required bool isDark,
  }) {
    final bool isSelected = _selectedStatus == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.08)
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey[200]!),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white24 : Colors.grey[400]),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white38 : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssuesList(bool isDark, Color surfaceColor, Color textColor) {
    final List<ClassroomIssue> filteredIssues = _issues.where((i) {
      String status = i.status.toLowerCase();
      if (_selectedStatus == 'Pending')
        return status == 'pending' || status == 'in review';
      return status == _selectedStatus.toLowerCase();
    }).toList();

    if (filteredIssues.isEmpty) {
      return _buildEmptyState(isDark, textColor);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredIssues.length,
      itemBuilder: (context, index) => _buildIssueCard(
        filteredIssues[index],
        isDark,
        surfaceColor,
        textColor,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100]!,
              ),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDark ? Colors.white10 : Colors.grey[200],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Clear Pipeline',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No $_selectedStatus cases found.',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(
    ClassroomIssue issue,
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    Color statusColor = Colors.orange;
    String status = issue.status.toLowerCase();
    if (status == 'resolved')
      statusColor = Colors.green;
    else if (status == 'rejected')
      statusColor = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueTrackingScreen(
                complaintId: issue.id,
                issueName: issue.issueName,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            issue.issueName.toLowerCase().contains('fan')
                                ? Icons.wind_power_rounded
                                : issue.issueName.toLowerCase().contains('proj')
                                ? Icons.video_label_rounded
                                : Icons.error_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          issue.issueName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        issue.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  issue.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildInfoBadge(
                      Icons.room_rounded,
                      issue.className,
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoBadge(
                      Icons.calendar_today_rounded,
                      issue.submittedAt.split(' ')[0],
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white24 : Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey[700],
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class IssueTrackingScreen extends StatefulWidget {
  final int complaintId;
  final String issueName;
  const IssueTrackingScreen({
    super.key,
    required this.complaintId,
    required this.issueName,
  });
  @override
  State<IssueTrackingScreen> createState() => _IssueTrackingScreenState();
}

class _IssueTrackingScreenState extends State<IssueTrackingScreen> {
  List<IssueTracking> _trackingHistory = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    final history = await ClassIssueService.getTracking(widget.complaintId);
    if (mounted)
      setState(() {
        _trackingHistory = history;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF0F1012)
        : const Color(0xFFF9FAFF);
    final Color surfaceColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Timeline Audit',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchTracking,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildTrackingHeader(
                      isDark,
                      surfaceColor,
                      textColor,
                    ),
                  ),
                  if (_trackingHistory.isEmpty)
                    SliverFillRemaining(child: _buildEmptyTracking(isDark))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildTimelineItem(
                            index,
                            isDark,
                            surfaceColor,
                            textColor,
                          ),
                          childCount: _trackingHistory.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTrackingHeader(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AUDIT TRAIL',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: #${widget.complaintId}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.issueName,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Detailed historical progression of this inquiry.',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTracking(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: isDark ? Colors.white10 : Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Text(
            'No progression recorded yet.',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    int index,
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    final track = _trackingHistory[index];
    final bool isLast = index == _trackingHistory.length - 1;
    final bool isFirst = index == 0;

    Color dotColor = isDark ? Colors.white12 : Colors.grey[300]!;
    if (isFirst)
      dotColor = AppColors.primary;
    else if (track.newStatus.toLowerCase() == 'resolved')
      dotColor = Colors.green;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: surfaceColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      track.newStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: track.newStatus.toLowerCase() == 'resolved'
                            ? Colors.green
                            : textColor,
                      ),
                    ),
                    Text(
                      track.changedDate,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white24 : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[50]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    track.note ?? 'Inquiry logged and awaiting further action.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
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
}

class SubmitIssueScreen extends StatefulWidget {
  const SubmitIssueScreen({super.key});
  @override
  State<SubmitIssueScreen> createState() => _SubmitIssueScreenState();
}

class _SubmitIssueScreenState extends State<SubmitIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  List<ClassIssueType> _categories = [];
  List<Map<String, dynamic>> _myClasses = [];
  int? _selectedCatNo;
  int? _selectedClsNo;
  bool _isLoadingInitial = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      ClassIssueService.getIssueTypes(),
      ClassIssueService.getMyClasses(),
    ]);
    if (mounted)
      setState(() {
        _categories = results[0] as List<ClassIssueType>;
        _myClasses = results[1] as List<Map<String, dynamic>>;
        if (_myClasses.isNotEmpty) _selectedClsNo = _myClasses[0]['cls_no'];
        _isLoadingInitial = false;
      });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCatNo == null ||
        _selectedClsNo == null)
      return;
    setState(() => _isSubmitting = true);
    final result = await ClassIssueService.submitIssue(
      _selectedCatNo!,
      _descriptionController.text,
      _selectedClsNo,
      _isOtherSelected ? _titleController.text : null,
    );
    setState(() => _isSubmitting = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted successfully')),
      );
      Navigator.pop(context, true);
    } else
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error')));
  }

  bool get _isOtherSelected {
    if (_selectedCatNo == null) return false;
    try {
      final cat = _categories.firstWhere((c) => c.catNo == _selectedCatNo);
      return cat.catName.toLowerCase().contains('other');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF0F1012)
        : const Color(0xFFF9FAFF);
    final Color surfaceColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Submit Inquiry',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isLoadingInitial
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernHeader(isDark, surfaceColor, textColor),
                          const SizedBox(height: 32),
                          _buildSectionTitle(
                            'Student Class',
                            'Which classroom is affected?',
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildClassSelector(isDark, surfaceColor, textColor),
                          const SizedBox(height: 32),
                          _buildSectionTitle(
                            'Student Category',
                            'What type of issue are you reporting?',
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDropdown(isDark, surfaceColor, textColor),
                          if (_isOtherSelected) ...[
                            const SizedBox(height: 32),
                            _buildSectionTitle(
                              'Issue Title',
                              'Briefly summarize the issue',
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildTitleTextField(
                              isDark,
                              surfaceColor,
                              textColor,
                            ),
                          ],
                          const SizedBox(height: 32),
                          _buildSectionTitle(
                            'Narrative Details',
                            'Provide a comprehensive description',
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            isDark,
                            surfaceColor,
                            textColor,
                          ),
                          const SizedBox(height: 40),
                          _buildSubmitButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernHeader(bool isDark, Color surfaceColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: const Icon(
              Icons.auto_awesome_motion_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Professional Reporting',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Submissions are prioritized by severity.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildClassSelector(bool isDark, Color surfaceColor, Color textColor) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _myClasses.length,
        itemBuilder: (context, index) {
          final cls = _myClasses[index];
          final bool isSelected = _selectedClsNo == cls['cls_no'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedClsNo = cls['cls_no']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey[200]!),
                    width: 1.5,
                  ),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    cls['cl_name'].toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernDropdown(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return DropdownButtonFormField<int>(
      value: _selectedCatNo,
      dropdownColor: surfaceColor,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: _premiumInputDecoration(
        hint: 'Select Student Category',
        icon: Icons.unfold_more_rounded,
        isDark: isDark,
        surfaceColor: surfaceColor,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? Colors.white24 : Colors.grey[400],
      ),
      items: _categories
          .map((t) => DropdownMenuItem(value: t.catNo, child: Text(t.catName)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCatNo = v),
      validator: (v) => v == null ? 'Selection required' : null,
    );
  }

  Widget _buildModernTextField(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 6,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: _premiumInputDecoration(
        hint: 'Please detail specific observations...',
        isDark: isDark,
        surfaceColor: surfaceColor,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
    );
  }

  Widget _buildSubmitButton() {
    const Color successGreen = Color(0xFF2ECC71);
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: successGreen.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SUBMIT INQUIRY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildTitleTextField(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: _premiumInputDecoration(
        hint: 'e.g., Broken Chair, AC Leak...',
        isDark: isDark,
        surfaceColor: surfaceColor,
      ),
      validator: (v) => _isOtherSelected && (v == null || v.isEmpty)
          ? 'Title required'
          : null,
    );
  }

  InputDecoration _premiumInputDecoration({
    required String hint,
    IconData? icon,
    required bool isDark,
    required Color surfaceColor,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null
          ? Icon(
              icon,
              color: isDark ? Colors.white12 : Colors.grey[300],
              size: 20,
            )
          : null,
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.all(20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.white24 : Colors.grey[400],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
