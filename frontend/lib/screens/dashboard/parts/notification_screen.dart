import 'package:flutter/material.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/app_error_widget.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.fetchNotifications();
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _notifications = result['notifications'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['message'] ?? 'Failed to load notifications';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          _buildAppBar(isDark),
          if (_isLoading && _notifications.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null && _notifications.isEmpty)
            SliverFillRemaining(
              child: AppErrorWidget(
                message: _error!,
                onRetry: _loadNotifications,
              ),
            )
          else if (_notifications.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildNotificationSliverList(isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay updated with your latest activities',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSliverList(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final notif = _notifications[index];
          return _buildNotificationCard(notif, isDark);
        }, childCount: _notifications.length),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark) {
    final title = notif['title'] ?? 'Notice';
    final message = notif['message'] ?? '';
    final isRead = (notif['is_read'] ?? 0) == 1;
    final createdAtStr = notif['created_at'] ?? '';

    DateTime? dt;
    String timeAgo = '';
    try {
      dt = DateTime.parse(createdAtStr);
      timeAgo = _formatTimeAgo(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? (isDark ? Colors.white12 : Colors.grey.shade200)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRead
                ? (isDark ? Colors.white10 : Colors.grey.shade100)
                : AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForModule(notif['module']),
            color: isRead
                ? (isDark ? Colors.white38 : Colors.grey)
                : AppColors.primary,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForModule(String? module) {
    switch (module?.toLowerCase()) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'class_issue':
        return Icons.class_rounded;
      case 'campus_env':
        return Icons.apartment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(dt);
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'All Caught Up!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You don\'t have any notifications at the moment.\nPull down to check for updates.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
