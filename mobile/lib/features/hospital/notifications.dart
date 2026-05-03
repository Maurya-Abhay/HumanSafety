import 'package:flutter/material.dart';
import '../../shared/widgets.dart'; // Ensure these widgets exist or replace with standard ones
import '../../shared/models.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/portal_sound_service.dart';

class HospitalNotificationsScreen extends StatefulWidget {
  const HospitalNotificationsScreen({super.key});

  @override
  State<HospitalNotificationsScreen> createState() => _HospitalNotificationsScreenState();
}

class _HospitalNotificationsScreenState extends State<HospitalNotificationsScreen> {
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
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final alerts = await ApiService.getHospitalAlerts(token);
      
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });

      if (alerts.isNotEmpty) {
        await PortalSoundService().playNotification();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      backgroundColor: const Color(0xFFF8FAFC), // Modern Light Grey Background
      appBar: AppBar(
        title: const Text('Hospital Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAlerts,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _buildErrorView()
                      : _filteredNotifications.isEmpty
                          ? _buildEmptyView()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final alert = _filteredNotifications[index];
                                return _buildNotificationCard(alert);
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
      width: double.infinity,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              elevation: 0,
              pressElevation: 0,
                  side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(CaseItem alert) {
    final view = _notificationViewForAlert(alert);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showAlertDetails(alert),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: view.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(view.icon, color: view.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            view.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          if (view.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        view.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(view.time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                          const Spacer(),
                          Text(
                            'View Details →',
                            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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

  _NotificationView _notificationViewForAlert(CaseItem alert) {
    final title = 'Case #${alert.caseId.isNotEmpty ? alert.caseId : alert.id.substring(0,5)}';
    final message = alert.description?.isNotEmpty == true ? alert.description! : 'Emergency ${alert.type} reported. Risk: ${alert.riskLevel}';
    final time = alert.createdAt != null ? _formatRelativeTime(alert.createdAt!) : 'Just now';
    final isUnread = alert.status.toLowerCase() != 'resolved';
    
    IconData icon = Icons.emergency_rounded;
    Color color = AppColors.primary;

    if (alert.type.toLowerCase().contains('ambulance')) {
      icon = Icons.local_shipping_rounded;
      color = const Color(0xFF10B981); // Green
    } else if (alert.riskLevel.toLowerCase() == 'high') {
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFEF4444); // Red
    }

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
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No alerts found', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load alerts', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            TextButton(onPressed: _loadAlerts, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(CaseItem alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('Alert Details', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Case ID', alert.caseId),
            _detailRow('Emergency Type', alert.type),
            _detailRow('Risk Level', '${alert.riskLevel} (${alert.riskScore})'),
            _detailRow('Status', alert.status.toUpperCase()),
            const SizedBox(height: 12),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(alert.description ?? 'No description provided.', style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
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