import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null && mounted) {
        context.read<StatsProvider>().fetchStats(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminSettings),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.adminUsers);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.adminReports);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.adminAnalytics);
        },
        items: [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.people, label: 'Users'),
          BottomNavItem(icon: Icons.report, label: 'Reports'),
          BottomNavItem(icon: Icons.analytics, label: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Consumer<StatsProvider>(
        builder: (context, statsProvider, _) {
          if (statsProvider.isLoading) {
            return const LoadingWidget();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'System Statistics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Total Users',
                '${statsProvider.totalUsers}',
                Icons.people,
                AppColors.primary,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Active Alerts',
                '${statsProvider.totalCases}',
                Icons.warning,
                AppColors.warning,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Resolved Cases',
                '${statsProvider.resolvedCases}',
                Icons.check_circle,
                AppColors.success,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Avg Response Time',
                '${statsProvider.avgResponseTime} min',
                Icons.local_hospital,
                AppColors.info,
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CustomCard(
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminRoleVerification),
                child: const ListTile(
                  leading: Icon(Icons.verified_user, color: AppColors.primary, size: 32),
                  title: Text('Verify Roles'),
                  subtitle: Text('Review user role applications'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
                child: const ListTile(
                  leading: Icon(Icons.group, color: AppColors.primary, size: 32),
                  title: Text('Manage Users'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminReports),
                child: const ListTile(
                  leading: Icon(Icons.description, color: AppColors.primary, size: 32),
                  title: Text('View Reports'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminAnalytics),
                child: const ListTile(
                  leading: Icon(Icons.trending_up, color: AppColors.primary, size: 32),
                  title: Text('View Analytics'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
