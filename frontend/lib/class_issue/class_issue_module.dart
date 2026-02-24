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
  ) async {
    try {
      final url = await _getApiUrl('/submit');
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'cat_no': catNo,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Issues'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshIssues,
                    child: _buildIssuesList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: _isLeader
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubmitIssueScreen()),
                );
                if (result == true) _refreshIssues();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Report Issue',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterChip(
            'Pending',
            Icons.hourglass_empty,
            color: Colors.orange,
          ),
          _buildFilterChip(
            'Resolved',
            Icons.check_circle_outline,
            color: Colors.green,
          ),
          _buildFilterChip(
            'Rejected',
            Icons.cancel_outlined,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, {Color? color}) {
    final bool isSelected = _selectedStatus == label;
    final Color activeColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    final List<ClassroomIssue> filteredIssues = _issues.where((i) {
      String status = i.status.toLowerCase();
      if (_selectedStatus == 'Pending') {
        return status == 'pending' || status == 'in review';
      }
      return status == _selectedStatus.toLowerCase();
    }).toList();

    if (filteredIssues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No $_selectedStatus issues found',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredIssues.length,
      itemBuilder: (context, index) => _buildIssueCard(filteredIssues[index]),
    );
  }

  Widget _buildIssueCard(ClassroomIssue issue) {
    Color statusColor = Colors.blue;
    String status = issue.status.toLowerCase();
    if (status == 'resolved') {
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
    } else if (status == 'pending' || status == 'in review') {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      issue.issueName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      issue.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.class_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        issue.className,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    issue.submittedAt.split(' ')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Issue Tracking Status'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTracking,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REPORTED ISSUE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.issueName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ID: #${widget.complaintId}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_trackingHistory.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No tracking history found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final track = _trackingHistory[index];
                          final bool isLast =
                              index == _trackingHistory.length - 1;
                          return Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: isLast
                                          ? Colors.green
                                          : Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 50,
                                      color: Colors.grey[200],
                                    ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          track.newStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isLast
                                                ? Colors.green
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          track.changedDate,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.03,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        track.note ?? 'Logged.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }, childCount: _trackingHistory.length),
                      ),
                    ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Class',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _myClasses
                          .map(
                            (cls) => ChoiceChip(
                              label: Text(cls['cl_name'].toString()),
                              selected: _selectedClsNo == cls['cls_no'],
                              onSelected: (val) {
                                if (val)
                                  setState(
                                    () => _selectedClsNo = cls['cls_no'],
                                  );
                              },
                              selectedColor: AppColors.primary.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      value: _selectedCatNo,
                      items: _categories
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.catNo,
                              child: Text(t.catName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCatNo = v),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      validator: (v) => v!.isEmpty ? 'Enter desc' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
