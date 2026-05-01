import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';
import '../../core/portal_sound_service.dart';

class HospitalNotificationsScreen extends StatefulWidget {
  const HospitalNotificationsScreen({super.key});

  @override
  State<HospitalNotificationsScreen> createState() =>
      _HospitalNotificationsScreenState();
}

class _HospitalNotificationsScreenState
    extends State<HospitalNotificationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'Emergency', 'Ambulance'];

  // Mock notifications data
  final List<_HospitalNotificationItem> _allNotifications = const [
    _HospitalNotificationItem(
      title: 'Emergency Alert',
      message:
          'Critical patient requiring immediate medical attention at Sector 7.',
      time: '2 min ago',
      icon: Icons.emergency_rounded,
      isUnread: true,
      category: 'Emergency',
      color: Colors.redAccent,
    ),
    _HospitalNotificationItem(
      title: 'Ambulance Dispatch',
      message: 'Ambulance #A-12 dispatched to downtown accident site.',
      time: '15 min ago',
      icon: Icons.directions_car_rounded,
      isUnread: false,
      category: 'Ambulance',
      color: Colors.blueAccent,
    ),
    _HospitalNotificationItem(
      title: 'Patient Update',
      message: 'Patient in Room 204 requires immediate attention.',
      time: '1 hour ago',
      icon: Icons.bed_rounded,
      isUnread: true,
      category: 'Emergency',
      color: Colors.orangeAccent,
    ),
    _HospitalNotificationItem(
      title: 'Medical Supply Alert',
      message: 'Low stock alert for critical medications in pharmacy.',
      time: '2 hours ago',
      icon: Icons.inventory_rounded,
      isUnread: false,
      category: 'Emergency',
      color: Colors.greenAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    PortalSoundService().playNotification();
  }

  List<_HospitalNotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'All') return _allNotifications;
    if (_selectedFilter == 'Unread')
      return _allNotifications.where((n) => n.isUnread).toList();
    return _allNotifications
        .where((n) => n.category == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Hospital Notifications',
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Simulate refresh
                await Future.delayed(const Duration(seconds: 1));
                setState(() {});
              },
              child: _filteredNotifications.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = _filteredNotifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildModernNotificationTile(notification),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor:
                  isSelected ? AppColors.primary : Colors.grey.shade200,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModernNotificationTile(_HospitalNotificationItem notification) {
    return CustomCard(
      child: InkWell(
        onTap: () {
          // Mark as read
          setState(() {
            // In real app, update the notification status
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.time,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
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
}

class _HospitalNotificationItem {
  const _HospitalNotificationItem({
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
