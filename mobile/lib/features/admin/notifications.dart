import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/portal_sound_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  // Mock data for filters
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'System', 'Applications'];

  @override
  void initState() {
    super.initState();
    PortalSoundService().playNotification();
  }

  final List<_AdminNotificationItem> _notifications = const [
    _AdminNotificationItem(
      title: 'New role application',
      message: 'A new police role request is waiting for verification.',
      time: '5 min ago',
      icon: Icons.verified_user_rounded,
      isUnread: true,
      category: 'Applications',
    ),
    _AdminNotificationItem(
      title: 'System health update',
      message: 'All emergency APIs are currently operational.',
      time: '30 min ago',
      icon: Icons.sensors_rounded,
      isUnread: false,
      category: 'System',
    ),
    _AdminNotificationItem(
      title: 'Pending report',
      message: 'A high-priority emergency report needs review.',
      time: '2 hours ago',
      icon: Icons.warning_amber_rounded,
      isUnread: true,
      category: 'System',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminProfile),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminSettings),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1E1E2E)]
                : [const Color(0xFFF8F9FA), Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildFilterChips(theme),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildModernNotificationTile(
                      _notifications[index], theme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == _filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (val) =>
                  setState(() => _selectedFilter = _filters[index]),
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              backgroundColor: theme.cardColor,
              side: BorderSide.none,
              elevation: isSelected ? 4 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernNotificationTile(
      _AdminNotificationItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: item.isUnread
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Indicator bar for unread
              if (item.isUnread) Container(width: 6, color: AppColors.primary),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationIcon(item),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: item.isUnread
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: item.isUnread
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                                Text(item.time,
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.message,
                              style: TextStyle(
                                color: item.isUnread ? null : AppColors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(_AdminNotificationItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isUnread
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        item.icon,
        color: item.isUnread ? AppColors.primary : AppColors.grey,
        size: 26,
      ),
    );
  }
}

class _AdminNotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isUnread;
  final String category;

  const _AdminNotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.isUnread,
    required this.category,
  });
}
