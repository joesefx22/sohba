import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    final notifications = notificationProvider.userNotifications(userId);
    final unreadCount = notificationProvider.unreadCount(userId);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Benachrichtigungen'),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                notificationProvider.markAllAsRead(userId);
              },
              child: const Text(
                'Alle gelesen',
                style: TextStyle(color: AppColors.teal),
              ),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Account for AppBar + status bar when extendBodyBehindAppBar is true
          final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

          if (notifications.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const EmptyState(
                icon: Icons.notifications_none,
                title: 'Keine Benachrichtigungen',
                description: 'Hier erscheinen deine Benachrichtigungen.',
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              top: topPadding + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationItem(
                context,
                notifications[index],
                notificationProvider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: notification.isRead
                ? null
                : const Border(
                    left: BorderSide(
                      color: AppColors.teal,
                      width: 3,
                    ),
                  ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon — AppIcons.get returns a fallback for legacy emoji
              // keys so older notifications stored as emoji strings still
              // render something sensible.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    AppIcons.get(notification.icon),
                    color: _getTypeColor(notification.type),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.questApproved:
        return AppColors.success;
      case NotificationType.questRejected:
        return AppColors.error;
      case NotificationType.questCompleted:
        return AppColors.teal;
      case NotificationType.rewardPurchased:
        return AppColors.gold;
      case NotificationType.rewardRedeemed:
        return AppColors.gold;
      case NotificationType.rewardConfirmed:
        return AppColors.success;
      case NotificationType.rewardRejected:
        return AppColors.error;
      case NotificationType.achievementUnlocked:
        return AppColors.rarityEpic;
      case NotificationType.streakMilestone:
        return AppColors.warning;
      case NotificationType.streakLost:
        return AppColors.error;
      case NotificationType.levelUp:
        return AppColors.rarityLegendary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (date == today) {
      return 'Heute, $time';
    } else if (date == yesterday) {
      return 'Gestern, $time';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}, $time';
    }
  }
}
