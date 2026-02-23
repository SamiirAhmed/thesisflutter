import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../models.dart';
import '../service.dart';
import 'submit_issue_screen.dart';
import 'issue_tracking_screen.dart';
import '../../services/api_service.dart';

class ClassIssueListScreen extends StatefulWidget {
  const ClassIssueListScreen({super.key});

  @override
  State<ClassIssueListScreen> createState() => _ClassIssueListScreenState();
}

class _ClassIssueListScreenState extends State<ClassIssueListScreen> {
  List<ClassroomIssue> _issues = [];
  bool _isLoading = true;
  bool _isLeader = false;

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
        if (issues.isEmpty) {
          debugPrint('Issues list came back empty from service.');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing issues: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading issues: $e')));
      }
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
          : RefreshIndicator(
              onRefresh: _refreshIssues,
              child: _issues.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _issues.length,
                      itemBuilder: (context, index) {
                        final issue = _issues[index];
                        return _buildIssueCard(issue);
                      },
                    ),
            ),
      floatingActionButton: _isLeader
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubmitIssueScreen()),
                );
                if (result == true) {
                  _refreshIssues();
                }
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

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Tap + to report or pull down to refresh',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildIssueCard(ClassroomIssue issue) {
    Color statusColor;
    switch (issue.status.toLowerCase()) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'in review':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueTrackingScreen(
                complaintId: issue.id,
                issueName: issue.issueName,
              ),
            ),
          );
        },
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
                    issue.submittedAt.split(' ')[0], // Date only
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
