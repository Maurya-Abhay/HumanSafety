import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart' as models;
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/portal_sound_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late String _token;
  List<models.Notification> notifications = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Soft background
      appBar: CustomAppBar(
        title: 'Activity Feed',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: "Mark all as read",
            onPressed: () {
              // Mark all read logic
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.userHome);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.sos);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.contacts);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.settings);
        },
        items: const [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.warning_amber_rounded, label: 'SOS'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return const Center(child: LoadingWidget());
    if (error != null) return _buildErrorState();
    if (notifications.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Dismissible(
            key: Key(notification.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _deleteNotification(notification.id),
            background: _buildDeleteBackground(),
            child: _buildNotificationCard(notification),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(models.Notification notification) {
    final bool isUnread = !notification.read;

    return GestureDetector(
      onTap: () => _markAsRead(notification.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Unread accent bar
              if (isUnread)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 5, color: AppColors.primary),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationIcon(notification),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.w900
                                      : FontWeight.bold,
                                  fontSize: 15,
                                  color: isUnread
                                      ? AppColors.black
                                      : AppColors.grey,
                                ),
                              ),
                              Text(
                                _formatTime(notification.timestamp),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread ? Colors.black87 : AppColors.grey,
                              height: 1.4,
                            ),
                          ),
                        ],
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

  Widget _buildNotificationIcon(models.Notification notification) {
    final bool isUnread = !notification.read;
    final IconData iconData = _getIconForType(notification.title);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.greyLight.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: isUnread ? AppColors.primary : AppColors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          Text("Delete",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded,
                size: 80, color: AppColors.primary.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text('Peace and Quiet',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('No new activity to show right now.',
              style: TextStyle(color: AppColors.grey)),
          const SizedBox(height: 32),
          SecondaryButton(
              label: "Check for Updates",
              onPressed: _loadNotifications,
              width: 200),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 60),
            const SizedBox(height: 16),
            const Text('Connection Lost',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(error ?? 'Failed to sync notifications',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Retry Sync', onPressed: _loadNotifications),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  IconData _getIconForType(String title) {
    final t = title.toLowerCase();
    if (t.contains('sos') || t.contains('emergency')) return Icons.bolt_rounded;
    if (t.contains('accident') || t.contains('impact'))
      return Icons.error_outline_rounded;
    if (t.contains('location') || t.contains('arrival'))
      return Icons.location_on_rounded;
    if (t.contains('contact')) return Icons.person_add_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  // --- Logic Placeholder ---
  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      // Mock data for UI testing
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        notifications = [
          models.Notification(
              id: '1',
              title: 'SOS Alert',
              message: 'Your emergency contact "Raj" triggered an SOS.',
              timestamp: DateTime.now(),
              read: false,
              type: 'sos'),
          models.Notification(
              id: '2',
              title: 'Safety Check',
              message: 'Are you safe? You reached your destination.',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              read: true,
              type: 'info'),
        ];
        isLoading = false;
      });
      await PortalSoundService().playNotification();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(String id) async {
    setState(() => notifications.removeWhere((n) => n.id == id));
    await PortalSoundService().playAlert();
    _showSnackBar("Notification removed");
  }

  Future<void> _markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !notifications[index].read) {
      setState(() =>
          notifications[index] = notifications[index].copyWith(read: true));
      await PortalSoundService().playNotification();
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}
