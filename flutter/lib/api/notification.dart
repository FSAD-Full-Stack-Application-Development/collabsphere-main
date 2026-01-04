import 'dart:convert';
import '../models/notification.dart';
import 'base_api.dart';

class NotificationService extends BaseApiService {
  NotificationService({required super.baseUrl});

  // Get notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool? unread,
    bool? read,
    String? type,
  }) async {
    final queryParams = <String, String>{};

    if (unread != null) queryParams['unread'] = unread.toString();
    if (read != null) queryParams['read'] = read.toString();
    if (type != null) queryParams['type'] = type;
    queryParams['page'] = page.toString();
    queryParams['per_page'] = perPage.toString();

    final response = await get('/notifications', params: queryParams);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final notifications =
          (data['notifications'] as List)
              .map((json) => Notification.fromJson(json))
              .toList();

      return {
        'notifications': notifications,
        'unread_count': data['unread_count'],
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final response = await post('/notifications/$notificationId/read');

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  // Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    final response = await post('/notifications/$notificationId/unread');

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as unread');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final response = await post('/notifications/read_all');

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final response = await delete('/notifications/$notificationId');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification');
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final response = await get('/notifications/unread_count');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unread_count'];
    } else {
      throw Exception('Failed to get unread count');
    }
  }
}

// Singleton instance
NotificationService notificationService = NotificationService(
  baseUrl: 'https://web06.cs.ait.ac.th/be/api/v1',
);
