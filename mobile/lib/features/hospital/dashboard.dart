import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
        final alerts = await ApiService.getHospitalAlerts(token);
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
        title: 'Hospital Dashboard',
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
          if (index == 1) Navigator.pushNamed(context, AppRoutes.hospitalRequests);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.hospitalAmbulance);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.hospitalProfile);
        },
        items: [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
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
            'Emergency Status',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildStatCard('Active Requests', _alerts.length.toString(), Icons.emergency_share, AppColors.accent),
          const SizedBox(height: 12),
          _buildStatCard('Pending', _alerts.where((a) => a.status == 'pending').length.toString(), Icons.directions_car, AppColors.success),
          const SizedBox(height: 12),
          _buildStatCard('Attended', _alerts.where((a) => a.status == 'attended').length.toString(), Icons.bed, AppColors.info),
          const SizedBox(height: 24),
          Text(
            'Recent Cases',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text('Error: $_error'))
          else if (_alerts.isEmpty)
            const Center(child: Text('No emergency requests'))
          else
            ..._alerts.take(2).map((alert) => CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                  child: const Icon(Icons.emergency, color: Colors.white),
                ),
                title: Text('Case ${alert.caseId}'),
                subtitle: Text('${alert.status} - Risk: ${alert.riskLevel}'),
                trailing: Chip(label: Text(alert.status)),
              ),
            )),
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
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
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
