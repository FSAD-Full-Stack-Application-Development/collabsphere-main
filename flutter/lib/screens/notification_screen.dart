import 'package:collab_sphere/screens/project_detail_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../api/notification.dart';
import '../api/project.dart';
import '../models/notification.dart' as notification_model;
import '../models/project.dart';
import '../store/auth_controller.dart';
import '../theme.dart';
import '../widgets/empty_states.dart';
import '../utils/responsive.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<notification_model.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  bool _error = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMorePages && !_loading) {
        _currentPage++;
        _fetchNotifications(loadMore: true);
      }
    }
  }

  Future<void> _fetchNotifications({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _loading = true;
        _error = false;
        _currentPage = 1;
      });
    }

    try {
      final result = await notificationService.getNotifications(
        page: _currentPage,
        perPage: 20,
      );

      final newNotifications =
          result['notifications'] as List<notification_model.Notification>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      setState(() {
        if (loadMore) {
          _notifications.addAll(newNotifications);
        } else {
          _notifications = newNotifications;
        }
        _unreadCount = result['unread_count'] as int;
        _hasMorePages = _currentPage < (pagination['total_pages'] as int);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await notificationService.markAsRead(notificationId);
      setState(() {
        final notification = _notifications.firstWhere(
          (n) => n.id == notificationId,
        );
        notification.read = true;
        notification.readAt = DateTime.now();
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notification as read')),
        );
      }
    }
  }

  Future<void> _markAsUnread(String notificationId) async {
    try {
      await notificationService.markAsUnread(notificationId);
      setState(() {
        final notification = _notifications.firstWhere(
          (n) => n.id == notificationId,
        );
        notification.read = false;
        notification.readAt = null;
        _unreadCount++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notification as unread'),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await notificationService.markAllAsRead();
      setState(() {
        for (final notification in _notifications) {
          notification.read = true;
          notification.readAt = DateTime.now();
        }
        _unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark all notifications as read'),
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await notificationService.deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete notification')),
        );
      }
    }
  }

  Future<void> _navigateToNotificationTarget(
    notification_model.Notification notification,
  ) async {
    final metadata = notification.metadata;
    if (metadata == null) return;

    final projectId = metadata['project_id'];
    if (projectId == null) return;

    try {
      // Fetch the project
      final response = await projectService.getProject(projectId.toString());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final project = Project.fromJson(data);

        // Determine if user is owner
        final isOwner = project.owner.id == authController.user?.id;

        // Navigate to project detail
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ProjectDetailPage(
                    projectId: project.id,
                    isOwner: isOwner,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      // If navigation fails, show a message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open project')));
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: AppTheme.accentGold),
              label: Text(
                'Mark all read',
                style: TextStyle(color: AppTheme.accentGold),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: RefreshIndicator(
          onRefresh: _fetchNotifications,
          child:
              _error
                  ? ListView(
                    padding: EdgeInsets.all(padding),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            const Text('Failed to load notifications'),
                            const SizedBox(height: AppTheme.spacingMd),
                            ElevatedButton(
                              onPressed: _fetchNotifications,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                  : _loading && _notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty && !_loading
                  ? ListView(
                    padding: EdgeInsets.all(padding),
                    children: const [
                      SizedBox(height: 200),
                      NoNotificationsState(),
                    ],
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(padding),
                    itemCount: _notifications.length + (_hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _notifications.length) {
                        // Loading indicator for pagination
                        return Container(
                          padding: EdgeInsets.all(AppTheme.spacingMd),
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentGold,
                            ),
                          ),
                        );
                      }
                      final notification = _notifications[index];
                      return GestureDetector(
                        onTap: () async {
                          if (!notification.read) {
                            await _markAsRead(notification.id);
                          }
                          await _navigateToNotificationTarget(notification);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: AppTheme.spacingXs),
                          padding: EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            gradient: AppTheme.gradientSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.accentGold.withOpacity(0.2),
                            ),
                            boxShadow: [AppTheme.shadowMd],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    notification.read
                                        ? AppTheme.bgLight
                                        : AppTheme.accentGold,
                                child: Icon(
                                  _getNotificationIcon(
                                    notification.notificationType,
                                  ),
                                  color:
                                      notification.read
                                          ? AppTheme.textLight
                                          : Colors.white,
                                ),
                              ),
                              SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.message,
                                      style: TextStyle(
                                        fontWeight:
                                            notification.read
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    SizedBox(height: AppTheme.spacingXs / 2),
                                    Text(
                                      _formatTimeAgo(notification.createdAt),
                                      style: TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'read':
                                      if (!notification.read) {
                                        _markAsRead(notification.id);
                                      }
                                      break;
                                    case 'unread':
                                      if (notification.read) {
                                        _markAsUnread(notification.id);
                                      }
                                      break;
                                    case 'delete':
                                      _deleteNotification(notification.id);
                                      break;
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      if (!notification.read)
                                        const PopupMenuItem(
                                          value: 'read',
                                          child: Text('Mark as read'),
                                        )
                                      else
                                        const PopupMenuItem(
                                          value: 'unread',
                                          child: Text('Mark as unread'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'collaboration_request':
      case 'collaboration_approved':
      case 'collaboration_rejected':
        return Icons.group;
      case 'funding_request':
      case 'funding_verified':
      case 'funding_rejected':
        return Icons.attach_money;
      case 'project_comment':
        return Icons.comment;
      case 'project_vote':
        return Icons.thumb_up;
      case 'new_message':
        return Icons.message;
      case 'resource_added':
        return Icons.file_present;
      case 'project_reported':
      case 'user_reported':
      case 'content_reported':
        return Icons.report;
      case 'user_suspended':
      case 'user_unsuspended':
        return Icons.admin_panel_settings;
      default:
        return Icons.notifications;
    }
  }
}
