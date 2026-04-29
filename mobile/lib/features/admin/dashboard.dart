import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

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
  // Index management ko sahi kiya
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final token = await StorageService.getString(AppConstants.tokenKey);
    if (token != null && mounted) {
      context.read<StatsProvider>().fetchStats(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
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
            icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminSettings),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.adminUsers);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.adminReports);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.adminAnalytics);
        },
        items: const [
          BottomNavItem(icon: Icons.grid_view_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.people_alt_rounded, label: 'Users'),
          BottomNavItem(icon: Icons.assignment_late_rounded, label: 'Reports'),
          BottomNavItem(icon: Icons.auto_graph_rounded, label: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading) return const Center(child: LoadingWidget());

        return RefreshIndicator(
          onRefresh: _refreshStats,
          child: ListView(
            // YAHAN FIX KIYA HAI: 110 ko 16 kar diya hai taaki faltu space na aaye
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20), 
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 24),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildModernStatCard('Total Users', '${stats.totalUsers}', Icons.groups_rounded, Colors.blue),
                  _buildModernStatCard('Emergency', '${stats.totalCases}', Icons.bolt_rounded, Colors.orange),
                  _buildModernStatCard('Resolved', '${stats.resolvedCases}', Icons.task_alt_rounded, Colors.green),
                  _buildModernStatCard('Response', '${stats.avgResponseTime}m', Icons.timer_rounded, Colors.purple),
                ],
              ),

              const SizedBox(height: 32),
              const _SectionLabel(label: 'Priority Actions'),
              const SizedBox(height: 16),

              _buildActionTile('Verification Center', 'Verify new police/medical credentials', Icons.admin_panel_settings_rounded, Colors.indigo, AppRoutes.adminRoleVerification),
              _buildActionTile('Incident Audit', 'Review detailed emergency logs', Icons.security_rounded, Colors.redAccent, AppRoutes.adminReports),
              _buildActionTile('Data Analytics', 'Deep dive into system performance', Icons.insights_rounded, Colors.teal, AppRoutes.adminAnalytics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Overview',
            style: TextStyle(
                color: AppColors.primary.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        const Text('Operational Status: Active',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildModernStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 80, color: color.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String sub, IconData icon, Color color, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(sub, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: AppColors.primary.withOpacity(0.1), thickness: 2)),
      ],
    );
  }
}