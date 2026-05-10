import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notifService, _) {
              if (notifService.unreadCount == 0) return const SizedBox();
              return TextButton(
                onPressed: notifService.markAllAsRead,
                child: Text('Baca Semua', style: TextStyle(color: theme.colorScheme.primary)),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notifService, _) {
          if (notifService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = notifService.notifications;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('Belum ada notifikasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Notifikasi order dan pesan\nakan muncul di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: notifService.fetchNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(
                  notif: notif,
                  onTap: () => _handleTap(context, notif, notifService),
                  onDismiss: () => notifService.deleteNotification(notif.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, NotificationModel notif, NotificationService service) {
    if (!notif.isRead) service.markAsRead(notif.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notif.title)),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({required this.notif, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.isRead;
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isUnread ? const Color(0xFFE8F4FD) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Color(notif.colorValue).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(notif.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14)),
                        ),
                        if (isUnread)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notif.body,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(timeago.format(notif.createdAt, locale: 'id'),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
