import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Notifications'),
      body: Consumer<NotificationsProvider>(
        builder: (context, notifProvider, _) {
          if (notifProvider.isLoading) {
            return const LoadingWidget();
          }
          if (notifProvider.notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = notifProvider.notifications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  onTap: () => notifProvider.markAsRead(notification.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(notification.message),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
