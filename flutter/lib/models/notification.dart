import 'user.dart';

class Notification {
  final String id;
  final String notificationType;
  final String message;
  bool read;
  DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final User? actor;
  final dynamic notifiable; // Can be Project, Comment, etc.

  Notification({
    required this.id,
    required this.notificationType,
    required this.message,
    required this.read,
    this.readAt,
    required this.createdAt,
    this.metadata,
    this.actor,
    this.notifiable,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      notificationType: json['notification_type'],
      message: json['message'],
      read: json['read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'],
      actor: json['actor'] != null ? User.fromJson(json['actor']) : null,
      notifiable: json['notifiable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_type': notificationType,
      'message': message,
      'read': read,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'actor': actor?.toJson(),
      'notifiable': notifiable,
    };
  }

  Notification copyWith({bool? read, DateTime? readAt}) {
    return Notification(
      id: id,
      notificationType: notificationType,
      message: message,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      metadata: metadata,
      actor: actor,
      notifiable: notifiable,
    );
  }
}
