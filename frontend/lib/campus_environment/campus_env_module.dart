import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/widgets/app_error_widget.dart';
import '../services/api_service.dart';

// ── MODELS ───────────────────────────────────────────────────────────────────

class CampusIssueType {
  final int id;
  final String name;

  CampusIssueType({required this.id, required this.name});

  factory CampusIssueType.fromJson(Map<String, dynamic> json) {
    return CampusIssueType(
      id: json['camp_env_no'] is int
          ? json['camp_env_no']
          : int.tryParse(json['camp_env_no'].toString()) ?? 0,
      name: json['campuses_issues']?.toString() ?? '',
    );
  }
}

class CampusComplaint {
  final int id;
  final String issueName;
  final String description;
  final String status;
  final String studentName;
  final String submittedAt;
  final int supportCount;
  final bool hasSupported;
  final String? title;
  final List<String> images;

  CampusComplaint({
    required this.id,
    required this.issueName,
    required this.description,
    required this.status,
    required this.studentName,
    required this.submittedAt,
    required this.supportCount,
    required this.hasSupported,
    this.title,
    required this.images,
  });

  factory CampusComplaint.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imgs = List<String>.from(json['images']);
      } else if (json['images'] is String) {
        try {
          imgs = List<String>.from(jsonDecode(json['images']));
        } catch (_) {}
      }
    }
    return CampusComplaint(
      id: int.tryParse(json['id'].toString()) ?? 0,
      issueName: json['issue_name']?.toString() ?? 'Unknown',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      studentName: json['student_name']?.toString() ?? 'Anonymous',
      submittedAt: json['submitted_at']?.toString() ?? '',
      supportCount: int.tryParse(json['support_count'].toString()) ?? 0,
      hasSupported: json['has_supported'] == true,
      title: json['title']?.toString(),
      images: imgs,
    );
  }
}

class CampusTracking {
  final int id;
  final String newStatus;
  final String? note;
  final String changedDate;

  CampusTracking({
    required this.id,
    required this.newStatus,
    this.note,
    required this.changedDate,
  });

  factory CampusTracking.fromJson(Map<String, dynamic> json) {
    return CampusTracking(
      id: int.tryParse(json['cet_no'].toString()) ?? 0,
      newStatus: json['new_status']?.toString() ?? 'Unknown',
      note: json['note']?.toString(),
      changedDate:
          json['changed_date']?.toString() ??
          json['created_at']?.toString() ??
          '',
    );
  }
}

// ── SERVICE ──────────────────────────────────────────────────────────────────

class CampusEnvService {
  static Future<String> _getApiUrl(String path) async {
    final baseUrl = await ApiService.getBaseUrl();
    return '$baseUrl/api/v1/campus-env$path';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<List<CampusIssueType>> getIssueTypes() async {
    try {
      final url = await _getApiUrl('/types');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return (decoded['data'] as List)
              .map((item) => CampusIssueType.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitComplaint({
    required int campEnvNo,
    required String description,
    String? title,
    List<File>? images,
  }) async {
    try {
      final url = await _getApiUrl('/submit');
      final headers = await _getHeaders();
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.fields['camp_env_no'] = campEnvNo.toString();
      request.fields['description'] = description;
      if (title != null) request.fields['title'] = title;

      if (images != null) {
        for (var img in images) {
          final ext = img.path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg';
          if (ext == 'png') mimeType = 'image/png';
          if (ext == 'gif') mimeType = 'image/gif';
          if (ext == 'webp') mimeType = 'image/webp';

          request.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              img.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<List<CampusComplaint>> getComplaints() async {
    try {
      final url = await _getApiUrl('/complaints');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return (decoded['data'] as List)
              .map((item) => CampusComplaint.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> toggleSupport(int complaintId) async {
    try {
      final url = await _getApiUrl('/support');
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'cmp_env_com_no': complaintId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<List<CampusTracking>> getTracking(int complaintId) async {
    try {
      final url = await _getApiUrl('/tracking/$complaintId');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return (decoded['data'] as List)
              .map((item) => CampusTracking.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String> getImageUrl(String path) async {
    final baseUrl = await ApiService.getBaseUrl();
    return '$baseUrl/storage/$path';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN 1: COMPLAINTS LIST (Main Screen)
// ══════════════════════════════════════════════════════════════════════════════

class CampusEnvListScreen extends StatefulWidget {
  const CampusEnvListScreen({super.key});
  @override
  State<CampusEnvListScreen> createState() => _CampusEnvListScreenState();
}

class _CampusEnvListScreenState extends State<CampusEnvListScreen>
    with SingleTickerProviderStateMixin {
  List<CampusComplaint> _complaints = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'All';
  late AnimationController _fabAnimController;

  static const _envGreen = Color(0xFF27AE60);
  static const _envTeal = Color(0xFF1ABC9C);
  static const _envDarkGreen = Color(0xFF1E8449);

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadComplaints();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    if (_complaints.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final list = await CampusEnvService.getComplaints();
      if (mounted) {
        setState(() {
          _complaints = list;
          _isLoading = false;
        });
        _fabAnimController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection to campus environment service failed.';
          _isLoading = false;
        });
        // Still show FAB so they can try to submit if it's just a list loading error
        _fabAnimController.forward();
      }
    }
  }

  List<CampusComplaint> get _filteredComplaints {
    if (_selectedStatus == 'All') return _complaints;
    return _complaints.where((c) {
      final s = c.status.toLowerCase();
      return s == _selectedStatus.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E13) : const Color(0xFFF8FBFA);
    final surfaceColor = isDark ? const Color(0xFF141A1F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2E1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, surfaceColor, textColor),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null && _complaints.isEmpty
          ? AppErrorWidget(message: _error!, onRetry: _loadComplaints)
          : RefreshIndicator(
              onRefresh: _loadComplaints,
              color: _envGreen,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildFilterBar(isDark, surfaceColor),
                  ),
                  SliverToBoxAdapter(
                    child: _buildStatsBar(isDark, surfaceColor, textColor),
                  ),
                  _filteredComplaints.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(isDark, textColor),
                        )
                      : _buildComplaintsSliverList(
                          isDark,
                          surfaceColor,
                          textColor,
                        ),
                ],
              ),
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF141A1F) : _envDarkGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, size: 22, color: Colors.white70),
          SizedBox(width: 8),
          Text(
            'Campus Environment',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      flexibleSpace: isDark
          ? null
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.2),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _envGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: _envGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading complaints...',
            style: TextStyle(
              color: _envGreen.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark, Color surfaceColor) {
    final filters = ['All', 'Pending', 'Resolved', 'Rejected'];
    return Container(
      color: isDark ? const Color(0xFF141A1F) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: filters.length,
          itemBuilder: (_, i) {
            final f = filters[i];
            final isActive = _selectedStatus == f;
            return GestureDetector(
              onTap: () => setState(() => _selectedStatus = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _envGreen
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? _envGreen
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE1E8E4)),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white54 : const Color(0xFF52605A)),
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsBar(bool isDark, Color surfaceColor, Color textColor) {
    final pending = _complaints.where((c) {
      final s = c.status.toLowerCase();
      return s == 'pending' || s == 'in review';
    }).length;
    final resolved = _complaints
        .where((c) => c.status.toLowerCase() == 'resolved')
        .length;
    final total = _complaints.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A2E1A), const Color(0xFF141A1F)]
              : [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? _envGreen.withValues(alpha: 0.15)
              : _envGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', total.toString(), Icons.list_alt_rounded, isDark),
          _dividerVertical(isDark),
          _statItem(
            'Active',
            pending.toString(),
            Icons.pending_actions_rounded,
            isDark,
          ),
          _dividerVertical(isDark),
          _statItem(
            'Fixed',
            resolved.toString(),
            Icons.check_circle_rounded,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: _envGreen.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1A2E1A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _dividerVertical(bool isDark) {
    return Container(
      width: 1,
      height: 35,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[200],
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: _envGreen.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.park_rounded,
                  size: 64,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : _envGreen.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Reports Found',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The campus looks great!\nTap + to report an issue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintsSliverList(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return SliverPadding(
      key: const PageStorageKey('campus_env_list_key'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildComplaintCard(
            _filteredComplaints[index],
            isDark,
            surfaceColor,
            textColor,
            index,
          ),
          childCount: _filteredComplaints.length,
        ),
      ),
    );
  }

  Widget _buildComplaintCard(
    CampusComplaint complaint,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    int index,
  ) {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_rounded;
    final s = complaint.status.toLowerCase();
    if (s == 'resolved') {
      statusColor = const Color(0xFF27AE60);
      statusIcon = Icons.check_circle_rounded;
    } else if (s == 'rejected') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8F0E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CampusEnvTrackingScreen(
                complaintId: complaint.id,
                issueName: complaint.issueName,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: issue name + status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _envGreen.withValues(alpha: 0.1),
                            _envTeal.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIssueIcon(complaint.issueName),
                        color: _envGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.issueName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${complaint.studentName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            complaint.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (complaint.title != null && complaint.title!.isNotEmpty) ...[
                  Text(
                    complaint.title!,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Description
                Text(
                  complaint.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Images preview
                if (complaint.images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_rounded,
                        size: 14,
                        color: _envGreen.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${complaint.images.length} photo(s)',
                        style: TextStyle(
                          color: _envGreen.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Bottom row: date + support
                Row(
                  children: [
                    _infoChip(
                      Icons.calendar_today_rounded,
                      complaint.submittedAt.split(' ')[0],
                      isDark,
                    ),
                    const Spacer(),
                    _buildSupportButton(complaint, isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportButton(CampusComplaint complaint, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final result = await CampusEnvService.toggleSupport(complaint.id);
        if (result['success'] == true) {
          _loadComplaints();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: complaint.hasSupported
              ? _envGreen.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF5F9F5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: complaint.hasSupported
                ? _envGreen.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey[200]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              complaint.hasSupported
                  ? Icons.thumb_up_rounded
                  : Icons.thumb_up_outlined,
              size: 16,
              color: complaint.hasSupported
                  ? _envGreen
                  : (isDark ? Colors.white38 : Colors.grey[500]),
            ),
            const SizedBox(width: 6),
            Text(
              '${complaint.supportCount}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: complaint.hasSupported
                    ? _envGreen
                    : (isDark ? Colors.white54 : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF5F9F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? Colors.white24 : Colors.grey[500],
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIssueIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('water') || lower.contains('leak'))
      return Icons.water_drop_rounded;
    if (lower.contains('gate') || lower.contains('door'))
      return Icons.door_front_door_rounded;
    if (lower.contains('light') || lower.contains('electric'))
      return Icons.lightbulb_rounded;
    if (lower.contains('road') || lower.contains('path'))
      return Icons.add_road_rounded;
    if (lower.contains('trash') || lower.contains('waste'))
      return Icons.delete_rounded;
    if (lower.contains('tree') || lower.contains('garden'))
      return Icons.park_rounded;
    if (lower.contains('toilet') || lower.contains('bathroom'))
      return Icons.wc_rounded;
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('security') || lower.contains('safe'))
      return Icons.security_rounded;
    return Icons.eco_rounded;
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimController,
        curve: Curves.elasticOut,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _envGreen.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'campus_env_fab',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SubmitCampusComplaintScreen(),
              ),
            );
            if (result == true) _loadComplaints();
          },
          backgroundColor: _envGreen,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          label: const Text(
            'REPORT ISSUE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN 2: SUBMIT COMPLAINT
// ══════════════════════════════════════════════════════════════════════════════

class SubmitCampusComplaintScreen extends StatefulWidget {
  const SubmitCampusComplaintScreen({super.key});
  @override
  State<SubmitCampusComplaintScreen> createState() =>
      _SubmitCampusComplaintScreenState();
}

class _SubmitCampusComplaintScreenState
    extends State<SubmitCampusComplaintScreen> {
  List<CampusIssueType> _issueTypes = [];
  CampusIssueType? _selectedType;
  final _descController = TextEditingController();
  final _titleController = TextEditingController();
  List<File> _selectedImages = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  static const _envGreen = Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _descController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final types = await CampusEnvService.getIssueTypes();
    if (mounted) {
      setState(() {
        _issueTypes = types;
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (_selectedImages.length >= 5) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF4C8C2B),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF4C8C2B),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      debugPrint('CampusEnv: Attempting to pick images from $source...');
      final picker = ImagePicker();

      if (source == ImageSource.camera) {
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 75,
        );
        if (picked != null && mounted) {
          setState(() {
            _selectedImages.add(File(picked.path));
          });
        }
      } else {
        final pickedSize = await picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 75,
        );

        if (pickedSize.isNotEmpty && mounted) {
          setState(() {
            _selectedImages.addAll(pickedSize.map((xf) => File(xf.path)));
            if (_selectedImages.length > 5) {
              _selectedImages = _selectedImages.sublist(0, 5);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('CampusEnv: Error picking images: $e');
      _showSnack('Error accessing media: $e', isError: true);
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      _showSnack('Please select an issue type.', isError: true);
      return;
    }
    if (_selectedType?.name.toLowerCase() == 'other' &&
        _titleController.text.trim().isEmpty) {
      _showSnack('Please enter a title for this issue.', isError: true);
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnack('Please describe the issue.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await CampusEnvService.submitComplaint(
      campEnvNo: _selectedType!.id,
      description: _descController.text.trim(),
      title: _selectedType?.name.toLowerCase() == 'other'
          ? _titleController.text.trim()
          : null,
      images: _selectedImages.isNotEmpty ? _selectedImages : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true) {
        _showSnack(result['message'] ?? 'Submitted!');
        Navigator.pop(context, true);
      } else {
        _showSnack(result['message'] ?? 'Failed to submit.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : _envGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E13) : const Color(0xFFF0F7F4);
    final surfaceColor = isDark ? const Color(0xFF141A1F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2E1A);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE0EDE0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF141A1F) : _envGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Report Issue',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        flexibleSpace: isDark
            ? null
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
                  ),
                ),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _envGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue Type Selector
                  _sectionLabel('Issue Type', textColor),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CampusIssueType>(
                        value: _selectedType,
                        hint: Text(
                          'Select issue type...',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: surfaceColor,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                        items: _issueTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(
                                  _getIssueIcon(t.name),
                                  size: 18,
                                  color: _envGreen,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  t.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedType = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_selectedType?.name.toLowerCase() == 'other') ...[
                    _sectionLabel('Title', textColor),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter a short title...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  _sectionLabel('Description', textColor),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _descController,
                      maxLines: 5,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe the campus issue in detail...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Images Section
                  _sectionLabel('Photos (optional, max 5)', textColor),
                  const SizedBox(height: 8),
                  _buildImagePicker(
                    isDark,
                    surfaceColor,
                    borderColor,
                    textColor,
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _envGreen,
                        disabledBackgroundColor: _envGreen.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'SUBMIT REPORT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePicker(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
  ) {
    return Column(
      children: [
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _selectedImages[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedImages.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Improved button with InkWell for visual feedback
        Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _selectedImages.length >= 5 ? null : _showImageSourceDialog,
            splashColor: _envGreen.withValues(alpha: 0.1),
            highlightColor: _envGreen.withValues(alpha: 0.05),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _envGreen.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 32,
                    color: _envGreen.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedImages.length >= 5
                        ? 'Maximum 5 photos reached'
                        : 'Tap to add photos',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  Widget _sectionLabel(String label, Color textColor) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: _envGreen,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );
  }

  IconData _getIssueIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('water') || lower.contains('leak'))
      return Icons.water_drop_rounded;
    if (lower.contains('gate') || lower.contains('door'))
      return Icons.door_front_door_rounded;
    if (lower.contains('light') || lower.contains('electric'))
      return Icons.lightbulb_rounded;
    if (lower.contains('road') || lower.contains('path'))
      return Icons.add_road_rounded;
    if (lower.contains('trash') || lower.contains('waste'))
      return Icons.delete_rounded;
    if (lower.contains('tree') || lower.contains('garden'))
      return Icons.park_rounded;
    if (lower.contains('toilet') || lower.contains('bathroom'))
      return Icons.wc_rounded;
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('security')) return Icons.security_rounded;
    return Icons.eco_rounded;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN 3: TRACKING TIMELINE
// ══════════════════════════════════════════════════════════════════════════════

class CampusEnvTrackingScreen extends StatefulWidget {
  final int complaintId;
  final String issueName;
  const CampusEnvTrackingScreen({
    super.key,
    required this.complaintId,
    required this.issueName,
  });
  @override
  State<CampusEnvTrackingScreen> createState() =>
      _CampusEnvTrackingScreenState();
}

class _CampusEnvTrackingScreenState extends State<CampusEnvTrackingScreen> {
  List<CampusTracking> _history = [];
  bool _isLoading = true;

  static const _envGreen = Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    final history = await CampusEnvService.getTracking(widget.complaintId);
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E13) : const Color(0xFFF0F7F4);
    final surfaceColor = isDark ? const Color(0xFF141A1F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2E1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF141A1F) : _envGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Tracking Timeline',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        flexibleSpace: isDark
            ? null
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
                  ),
                ),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _envGreen))
          : RefreshIndicator(
              onRefresh: _loadTracking,
              color: _envGreen,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      color: surfaceColor,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AUDIT TRAIL',
                            style: TextStyle(
                              color: _envGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _envGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.eco_rounded,
                                  color: _envGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.issueName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      'Complaint #${widget.complaintId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey[500],
                                        fontWeight: FontWeight.w600,
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
                  ),

                  // Timeline items
                  if (_history.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No tracking records yet.',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildTimelineItem(
                            index,
                            isDark,
                            surfaceColor,
                            textColor,
                          ),
                          childCount: _history.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimelineItem(
    int index,
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    final item = _history[index];
    final isLast = index == _history.length - 1;

    Color dotColor = Colors.orange;
    final s = item.newStatus.toLowerCase();
    if (s == 'resolved') dotColor = _envGreen;
    if (s == 'rejected') dotColor = Colors.redAccent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFE8F0E8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.newStatus.toUpperCase(),
                      style: TextStyle(
                        color: dotColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.note!,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    item.changedDate,
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
