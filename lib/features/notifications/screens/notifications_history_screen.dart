// lib/features/notifications/screens/notifications_history_screen.dart
import 'package:flutter/material.dart';
import 'package:mediremind/core/models/notification_model_flutter.dart';
import 'package:mediremind/core/services/notification_service_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsHistoryScreen extends StatefulWidget {
  const NotificationsHistoryScreen({super.key});

  @override
  State<NotificationsHistoryScreen> createState() => _NotificationsHistoryScreenState();
}

class _NotificationsHistoryScreenState extends State<NotificationsHistoryScreen> {
  final NotificationServiceFlutter _notificationService = NotificationServiceFlutter();
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    if(mounted){
      setState(() {
        _notificationsFuture = _notificationService.getMyNotificationsHistory();
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.status != 'read') {
      try {
        await _notificationService.markNotificationAsRead(notification.id);
        _loadNotifications(); // Recargar para reflejar el cambio
      } catch (e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al marcar como leída: ${e.toString()}')),
          );
        }
      }
    }
  }

  IconData _getIconForNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'medication_dose_reminder':
        return Icons.alarm_on_outlined;
      case 'appointment_reminder_24h':
      case 'appointment_confirmed':
      case 'appointment_updated':
      case 'appointment_created':
        return Icons.calendar_today_outlined;
      case 'appointment_cancelled_by_doctor':
        return Icons.event_busy_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notificaciones'),
        elevation: 1,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar notificaciones: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No tienes notificaciones.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                   const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    onPressed: _loadNotifications,
                  )
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final bool isRead = notification.status == 'read';
                final DateFormat dateFormat = DateFormat('dd MMM, yyyy \'a las\' hh:mm a', 'es_MX');
                String displayDate = 'Fecha no disponible';
                if(notification.createdAt != null){
                    displayDate = dateFormat.format(notification.createdAt!.toLocal());
                } else if (notification.sendAt != null) {
                    displayDate = "Programada para: ${dateFormat.format(notification.sendAt!.toLocal())}";
                }


                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead 
                        ? Colors.grey.shade300 
                        : Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Icon(
                      _getIconForNotificationType(notification.type),
                      color: isRead ? Colors.grey.shade600 : Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: isRead ? Colors.grey.shade700 : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "${notification.type.replaceAll('_', ' ').toUpperCase()}\n$displayDate",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Navegar a la pantalla relevante si es necesario
                    // Por ahora, solo marcar como leída
                    _markAsRead(notification);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
