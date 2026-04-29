import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

class PoliceNotificationsScreen extends StatefulWidget {
  const PoliceNotificationsScreen({super.key});

  @override
  State<PoliceNotificationsScreen> createState() =>
      _PoliceNotificationsScreenState();
}

class _PoliceNotificationsScreenState extends State<PoliceNotificationsScreen> {
  // Mock data for filters
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'Emergency', 'Patrol'];

  final List<_PoliceNotificationItem> _notifications = const [
    _PoliceNotificationItem(
      title: 'Emergency Alert',
      message: 'High-priority SOS from Sector 7. Respond immediately.',
      time: '2 min ago',
      icon: Icons.emergency_rounded,
      isUnread: true,
      category: 'Emergency',
    ),
    _PoliceNotificationItem(
      title: 'Patrol Assignment',
      message: 'New patrol route assigned for downtown area.',
      time: '15 min ago',
      icon: Icons.directions_car_rounded,
      isUnread: false,
      category: 'Patrol',
    ),
    _PoliceNotificationItem(
      title: 'Case Update',
      message: 'Investigation report for Case #1234 has been updated.',
      time: '1 hour ago',
      icon: Icons.assignment_rounded,
      isUnread: true,
      category: 'Emergency',
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
                Navigator.pushNamed(context, AppRoutes.policeProfile),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.policeSettings),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      _PoliceNotificationItem item, ThemeData theme) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isUnread
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            item.icon,
            color: item.isUnread ? AppColors.primary : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.time,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: item.isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          // Mark as read
          setState(() {
            // In real app, update the item
          });
        },
      ),
    );
  }
}

class _PoliceNotificationItem {
  const _PoliceNotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.isUnread,
    required this.category,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isUnread;
  final String category;
}
