class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? orderId;
  final String? chatRoomId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.chatRoomId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      orderId: map['order_id'] as String?,
      chatRoomId: map['chat_room_id'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      chatRoomId: chatRoomId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get icon {
    switch (type) {
      case 'order_new': return '🛵';
      case 'order_accepted': return '✅';
      case 'order_picked': return '📦';
      case 'order_delivered': return '🎉';
      case 'chat_new': return '💬';
      default: return '🔔';
    }
  }

  int get colorValue {
    switch (type) {
      case 'order_new': return 0xFF2196F3;
      case 'order_accepted': return 0xFF4CAF50;
      case 'order_picked': return 0xFFFF9800;
      case 'order_delivered': return 0xFF9C27B0;
      case 'chat_new': return 0xFF00BCD4;
      default: return 0xFF607D8B;
    }
  }
}
