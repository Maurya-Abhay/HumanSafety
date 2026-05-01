import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network_client.dart';
import 'dart:convert';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      setState(() => _isLoading = true);
      final token = await StorageService.getString(AppConstants.tokenKey);
      
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/admin/analytics', options: Options(headers: {
        'Authorization': 'Bearer $token',
      }));

      if (resp.statusCode == 200) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        setState(() {
          _analytics = (data as Map<String, dynamic>)['analytics'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch analytics';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Analytics',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminProfile),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminSettings),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _fetchAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'System Overview',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildAnalyticsSection('Active Users', _analytics),
                        const SizedBox(height: 24),
                        Text(
                          'Breakdown by Role',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildRoleStats(),
                        const SizedBox(height: 24),
                        Text(
                          'System Health',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildHealthMetrics(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.adminDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.adminUsers);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.adminReports);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.adminAnalytics);
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

  Widget _buildAnalyticsSection(String title, Map<String, dynamic> data) {
    return CustomCard(
      child: Column(
        children: [
          _buildMetricRow(
            'Active Users',
            '${data['active']?['users'] ?? 0}',
            Icons.person,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Active Police',
            '${data['active']?['police'] ?? 0}',
            Icons.security,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Active Hospitals',
            '${data['active']?['hospitals'] ?? 0}',
            Icons.local_hospital,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleStats() {
    final active = _analytics['active'] ?? {};
    final rejected = _analytics['rejected'] ?? {};
    
    return CustomCard(
      child: Column(
        children: [
          _buildRoleRow('Police - Active', '${active['police'] ?? 0}', AppColors.primary),
          const SizedBox(height: 12),
          _buildRoleRow('Police - Rejected', '${rejected['police'] ?? 0}', Colors.red),
          const SizedBox(height: 12),
          _buildRoleRow('Hospital - Active', '${active['hospitals'] ?? 0}', AppColors.success),
          const SizedBox(height: 12),
          _buildRoleRow('Hospital - Rejected', '${rejected['hospitals'] ?? 0}', Colors.red),
        ],
      ),
    );
  }

  Widget _buildRoleRow(String label, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    return CustomCard(
      child: Column(
        children: [
          _buildHealthRow('Blocked Accounts', '${_analytics['blocked'] ?? 0}', Colors.red),
          const SizedBox(height: 12),
          _buildHealthRow('System Status', 'Online', AppColors.success),
          const SizedBox(height: 12),
          _buildHealthRow('API Health', 'Operational', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
