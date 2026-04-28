import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<CaseItem> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null) {
        final alerts = await ApiService.getPoliceAlerts(token);
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Police Dashboard',
        showBackButton: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.policeAlerts);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.policeCases);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.policeProfile);
        },
        items: [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.warning, label: 'Alerts'),
          BottomNavItem(icon: Icons.description, label: 'Cases'),
          BottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Duty Status',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildStatCard('Active Alerts', _alerts.length.toString(), Icons.warning, AppColors.warning),
          const SizedBox(height: 12),
          _buildStatCard('Pending Cases', _alerts.where((a) => a.status == 'pending').length.toString(), Icons.people, AppColors.primary),
          const SizedBox(height: 12),
          _buildStatCard('Resolved', _alerts.where((a) => a.status == 'resolved').length.toString(), Icons.check_circle, AppColors.success),
          const SizedBox(height: 24),
          Text(
            'Recent Alerts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text('Error: $_error'))
          else if (_alerts.isEmpty)
            const Center(child: Text('No alerts'))
          else
            ..._alerts.take(3).map((alert) => CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.warning),
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
                title: Text('Case ${alert.caseId}'),
                subtitle: Text('${alert.status} - Risk: ${alert.riskLevel}'),
                trailing: Chip(label: Text(alert.status)),
              ),
            )),
          const SizedBox(height: 12),
          CustomCard(
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                child: const Icon(Icons.security, color: Colors.white),
              ),
              title: const Text('Security Incident'),
              subtitle: const Text('Reported 25 mins ago'),
              trailing: const Chip(label: Text('In Progress')),
            ),
          ),
        ],
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
