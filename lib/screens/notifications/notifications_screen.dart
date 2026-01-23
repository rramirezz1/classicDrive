import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../widgets/modern_card.dart';

/// Modelo para notificação in-app.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? actionRoute;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.actionRoute,
  });
}

enum NotificationType { booking, message, promo, system }

/// Classe pública para gerir estado das notificações globalmente.
class NotificationState {
  static List<AppNotification> notifications = [];
  
  static int get unreadCount => notifications.where((n) => !n.isRead).length;
  
  static void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = notifications[index];
      notifications[index] = AppNotification(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timestamp: notification.timestamp,
        type: notification.type,
        isRead: true,
        actionRoute: notification.actionRoute,
      );
    }
  }
  
  static void markAllAsRead() {
    notifications = notifications.map((n) => AppNotification(
      id: n.id,
      title: n.title,
      message: n.message,
      timestamp: n.timestamp,
      type: n.type,
      isRead: true,
      actionRoute: n.actionRoute,
    )).toList();
  }
}

/// Ecrã de notificações in-app.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    // Simular carregamento - só carregar dados se lista estiver vazia
    await Future.delayed(const Duration(milliseconds: 300));

    if (NotificationState.notifications.isEmpty) {
      // Dados de exemplo - só carrega uma vez
      NotificationState.notifications = [
        AppNotification(
          id: '1',
          title: 'Reserva Confirmada',
          message: 'A sua reserva do Mercedes-Benz 300SL foi confirmada pelo proprietário.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.booking,
          actionRoute: '/bookings',
        ),
        AppNotification(
          id: '2',
          title: 'Nova Avaliação',
          message: 'Um cliente deixou uma avaliação no seu veículo.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.message,
        ),
        AppNotification(
          id: '3',
          title: 'Promoção Especial',
          message: 'Aproveite 15% de desconto em reservas este fim de semana!',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          type: NotificationType.promo,
          isRead: true,
        ),
      ];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _markAsRead(String id) {
    setState(() {
      NotificationState.markAsRead(id);
    });
  }

  void _markAllAsRead() {
    setState(() {
      NotificationState.markAllAsRead();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Todas as notificações marcadas como lidas'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
    );
  }

  int get unreadCount => NotificationState.unreadCount;
  List<AppNotification> get _notifications => NotificationState.notifications;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notificações'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: AppRadius.borderRadiusFull,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Ler Tudo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('notif_anim_${_notifications[index].id}'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 200 + (index * 50)),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: _buildNotificationCard(
                          isDark,
                          _notifications[index],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.infoOpacity10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sem notificações',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'As suas notificações aparecerão aqui',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(bool isDark, AppNotification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.booking:
        icon = Icons.calendar_today_rounded;
        color = AppColors.primary;
        break;
      case NotificationType.message:
        icon = Icons.message_rounded;
        color = AppColors.info;
        break;
      case NotificationType.promo:
        icon = Icons.local_offer_rounded;
        color = AppColors.success;
        break;
      case NotificationType.system:
        icon = Icons.settings_rounded;
        color = AppColors.warning;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        useGlass: false,
        padding: EdgeInsets.zero,
        onTap: () {
          _markAsRead(notification.id);
          if (notification.actionRoute != null) {
            // Navegar se houver rota
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: notification.isRead
                ? null
                : Border(
                    left: BorderSide(color: color, width: 4),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return 'Há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Há ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Há ${diff.inDays} dias';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}
