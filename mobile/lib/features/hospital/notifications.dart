import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
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
  List<CaseItem> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null || token.isEmpty) {
        setState(() {
          _alerts = [];
        });
        return;
      }

      final alerts = await ApiService.getHospitalAlerts(token);
      if (!mounted) return;
      setState(() => _alerts = alerts);
      if (alerts.isNotEmpty) {
        await PortalSoundService().playNotification();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CaseItem> get _filteredNotifications {
    if (_selectedFilter == 'All') return _alerts;
    if (_selectedFilter == 'Unread') {
      return _alerts.where((n) => n.status.toLowerCase() != 'resolved').toList();
    }
    if (_selectedFilter == 'Ambulance') {
      return _alerts.where((n) => n.type.toLowerCase().contains('ambulance')).toList();
    }
    return _alerts.where((n) => n.type.toLowerCase().contains('panic') || n.riskLevel.toLowerCase() == 'high').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Hospital Alerts',
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAlerts,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _filteredNotifications.isEmpty
                          ? const Center(child: Text('No alerts found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final alert = _filteredNotifications[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildModernNotificationTile(alert),
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
      height: 64,
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
              backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade200,
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

  Widget _buildModernNotificationTile(CaseItem alert) {
    final view = _notificationViewForAlert(alert);
    return CustomCard(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      child: InkWell(
        onTap: () => _showAlertDetails(alert),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: view.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  view.icon,
                  color: view.color,
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
                            view.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (view.isUnread)
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
                      view.message,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      view.time,
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

  _NotificationView _notificationViewForAlert(CaseItem alert) {
    final title = 'Case ${alert.caseId.isNotEmpty ? alert.caseId : alert.id}';
    final message = alert.description?.isNotEmpty == true
        ? alert.description!
        : 'Type: ${alert.type} | Risk: ${alert.riskLevel}';
    final time = alert.createdAt != null
        ? _formatRelativeTime(alert.createdAt!)
        : 'Just now';
    final isUnread = alert.status.toLowerCase() != 'resolved';
    final icon = alert.type.toLowerCase().contains('ambulance')
        ? Icons.directions_car_rounded
        : Icons.emergency_rounded;
    final color = alert.riskLevel.toLowerCase() == 'high'
        ? Colors.redAccent
        : alert.riskLevel.toLowerCase() == 'medium'
            ? Colors.orangeAccent
            : Colors.blueAccent;

    return _NotificationView(
      title: title,
      message: message,
      time: time,
      icon: icon,
      isUnread: isUnread,
      color: color,
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  void _showAlertDetails(CaseItem alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.emergency_rounded, color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            Text('Case ${alert.caseId.isNotEmpty ? alert.caseId : alert.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(alert.description ?? 'No description available', style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 12),
            Text('Status: ${alert.status}'),
            Text('Type: ${alert.type}'),
            Text('Risk: ${alert.riskLevel} (${alert.riskScore})'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationView {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isUnread;
  final Color color;

  const _NotificationView({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.isUnread,
    required this.color,
  });
}
