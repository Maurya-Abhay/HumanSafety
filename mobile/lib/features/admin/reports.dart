import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network_client.dart';
import 'dart:convert';
import 'dart:ui';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      setState(() => _isLoading = true);
      final token = await StorageService.getString(AppConstants.tokenKey);

      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/cases/pending', options: Options(headers: {
        'Authorization': 'Bearer $token',
      }));

      if (resp.statusCode == 200) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        setState(() {
          _reports = (data as Map<String, dynamic>)['cases'] ?? data ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch reports';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredReports() {
    if (_statusFilter == 'all') return _reports;
    return _reports.where((r) => r['status'] == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _getFilteredReports();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reports',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminNotifications),
          ),
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
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -50,
            child: _DecorativeCircle(
                color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              _buildFilterSection(theme),
              Expanded(
                child: _isLoading
                    ? _buildSkeletonLoading()
                    : _error != null
                        ? _buildErrorState()
                        : filtered.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _fetchReports,
                                color: AppColors.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 10, 20, 100),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) =>
                                      _buildModernReportCard(
                                          filtered[index], theme),
                                ),
                              ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0)
            Navigator.pushNamed(context, AppRoutes.adminDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.adminUsers);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.adminReports);
          if (index == 3)
            Navigator.pushNamed(context, AppRoutes.adminAnalytics);
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.people, label: 'Users'),
          BottomNavItem(icon: Icons.report, label: 'Reports'),
          BottomNavItem(icon: Icons.analytics, label: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    final filters = ['all', 'pending', 'active', 'resolved'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _statusFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter[0].toUpperCase() + filter.substring(1)),
              selected: isSelected,
              onSelected: (_) => setState(() => _statusFilter = filter),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: theme.cardColor,
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernReportCard(dynamic report, ThemeData theme) {
    final status = report['status']?.toString().toLowerCase() ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: InkWell(
        onTap: () {}, // Detail page navigation
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.emergency_rounded,
                        color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['title'] ??
                              report['description'] ??
                              'Emergency Case',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: #${report['_id']?.toString().substring(18, 24).toUpperCase() ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status, statusColor),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Text(
                report['description'] ?? 'No additional details provided.',
                style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                    height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconText(
                      Icons.priority_high_rounded,
                      'Priority: ${report['priority'] ?? 'HIGH'}',
                      Colors.orange),
                  _buildIconText(
                      Icons.access_time_rounded, '2 mins ago', AppColors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  // Navigation consistent with Dashboard/Profile
  Widget _buildPremiumNav(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.dashboard_rounded, AppRoutes.adminDashboard, false),
          _navIcon(Icons.people_alt_rounded, AppRoutes.adminUsers, false),
          _navIcon(Icons.assignment_rounded, AppRoutes.adminReports, true),
          _navIcon(Icons.insights_rounded, AppRoutes.adminAnalytics, false),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String route, bool isSelected) {
    return GestureDetector(
      onTap: () => isSelected ? null : Navigator.pushNamed(context, route),
      child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.redAccent;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildSkeletonLoading() => const Center(child: LoadingWidget());
  Widget _buildErrorState() => Center(
      child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
  Widget _buildEmptyState() => const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: AppColors.grey),
          SizedBox(height: 16),
          Text('No cases found',
              style: TextStyle(color: AppColors.grey, fontSize: 18)),
        ],
      ));
}

class _DecorativeCircle extends StatelessWidget {
  final Color color;
  const _DecorativeCircle({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}
