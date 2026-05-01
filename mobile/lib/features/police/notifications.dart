import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/portal_sound_service.dart';

class PoliceNotificationsScreen extends StatefulWidget {
  const PoliceNotificationsScreen({super.key});

  @override
  State<PoliceNotificationsScreen> createState() =>
      _PoliceNotificationsScreenState();
}

class _PoliceNotificationsScreenState extends State<PoliceNotificationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'Emergency', 'Patrol'];

  // List ko 'late' banaya taaki filters apply ho sakein
  final List<_PoliceNotificationItem> _allNotifications = const [
    _PoliceNotificationItem(
      title: 'Emergency Alert',
      message: 'High-priority SOS from Sector 7. Respond immediately.',
      time: '2 min ago',
      icon: Icons.emergency_rounded,
      isUnread: true,
      category: 'Emergency',
      color: Colors.redAccent,
    ),
    _PoliceNotificationItem(
      title: 'Patrol Assignment',
      message: 'New patrol route assigned for downtown area.',
      time: '15 min ago',
      icon: Icons.directions_car_rounded,
      isUnread: false,
      category: 'Patrol',
      color: Colors.blueAccent,
    ),
    _PoliceNotificationItem(
      title: 'Case Update',
      message: 'Investigation report for Case #1234 has been updated.',
      time: '1 hour ago',
      icon: Icons.assignment_rounded,
      isUnread: true,
      category: 'Emergency',
      color: Colors.orangeAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    PortalSoundService().playAlert();
  }

  List<_PoliceNotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'All') return _allNotifications;
    if (_selectedFilter == 'Unread') return _allNotifications.where((n) => n.isUnread).toList();
    return _allNotifications.where((n) => n.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: 'Mark all as read',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildModernNotificationTile(
                          _filteredNotifications[index], theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = filter),
              selectedColor: AppColors.primary,
              backgroundColor: theme.cardColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
              ),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernNotificationTile(_PoliceNotificationItem item, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.isUnread 
                ? item.color.withOpacity(0.1) 
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
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
                              fontWeight: item.isUnread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 15,
                              color: item.isUnread ? null : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            item.time,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        style: TextStyle(
                          color: item.isUnread ? Colors.black87 : Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      if (item.isUnread) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEW ACTION',
                            style: TextStyle(color: item.color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No notifications found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
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
    required this.color,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isUnread;
  final String category;
  final Color color;
}