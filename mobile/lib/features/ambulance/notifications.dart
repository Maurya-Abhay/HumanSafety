import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';

class AmbulanceNotificationsScreen extends StatefulWidget {
  const AmbulanceNotificationsScreen({super.key});

  @override
  State<AmbulanceNotificationsScreen> createState() => _AmbulanceNotificationsScreenState();
}

class _AmbulanceNotificationsScreenState extends State<AmbulanceNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<NotificationsProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Notifications'),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notification_important, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.notifications.length,
            itemBuilder: (_, idx) {
              final notif = provider.notifications[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    notif.type == 'error' ? Icons.error : Icons.info,
                    color: notif.type == 'error' ? Colors.red : Colors.blue,
                  ),
                  title: Text(notif.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif.message),
                      Text(
                        notif.createdAt.toString().split('.')[0],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: notif.isRead
                      ? const Icon(Icons.done_all, color: Colors.green)
                      : const Icon(Icons.circle, color: Colors.blue, size: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
