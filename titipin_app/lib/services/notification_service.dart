import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _db = Supabase.instance.client;

  List<NotificationModel> _notifications = [];
  RealtimeChannel? _channel;
  bool _isLoading = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await fetchNotifications();
    await Future.delayed(const Duration(milliseconds: 500));
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _db
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      _notifications = (data as List)
          .map((row) => NotificationModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[NotificationService] fetchNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    _channel?.unsubscribe();
    _channel = _db
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newNotif = NotificationModel.fromMap(
              payload.newRecord as Map<String, dynamic>,
            );
            _notifications.insert(0, newNotif);
            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> notifyDriverNewOrder({
    required String driverId,
    required String orderId,
    required String orderInfo,
  }) async {
    await _insertNotification(
      userId: driverId,
      type: 'order_new',
      title: '🛵 Ada Order Baru!',
      body: orderInfo,
      orderId: orderId,
    );
  }

  Future<void> notifyWargaOrderAccepted({
    required String wargaId,
    required String orderId,
    required String driverName,
  }) async {
    await _insertNotification(
      userId: wargaId,
      type: 'order_accepted',
      title: '✅ Pesanan Diterima!',
      body: '$driverName sedang menuju ke lokasi Anda.',
      orderId: orderId,
    );
  }

  Future<void> notifyNewChat({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    final myId = _db.auth.currentUser?.id;
    if (recipientId == myId) return;
    await _insertNotification(
      userId: recipientId,
      type: 'chat_new',
      title: '💬 Pesan dari $senderName',
      body: message.length > 60 ? '${message.substring(0, 60)}...' : message,
      chatRoomId: chatRoomId,
    );
  }

  Future<void> _insertNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? orderId,
    String? chatRoomId,
  }) async {
    try {
      await _db.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        if (orderId != null) 'order_id': orderId,
        if (chatRoomId != null) 'chat_room_id': chatRoomId,
      });
    } catch (e) {
      debugPrint('[NotificationService] _insertNotification error: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationService] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.from('notifications').delete().eq('id', notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] deleteNotification error: $e');
    }
  }
}