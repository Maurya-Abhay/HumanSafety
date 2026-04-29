import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart'; // Ensure CaseItem model is imported
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
        if (mounted) {
          setState(() {
            _alerts = alerts;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Modern subtle background
      appBar: CustomAppBar(
        title: 'Police Dashboard',
        showBackButton: false,
        actions: [
          _buildActionIcon(Icons.notifications_none_rounded, AppRoutes.policeNotifications),
          _buildActionIcon(Icons.person_outline_rounded, AppRoutes.policeProfile),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadAlerts,
            child: _buildBody(),
          ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.policeAlerts);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.policeCases);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.policeSettings);
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.bolt_rounded, label: 'Alerts'),
          BottomNavItem(icon: Icons.assignment_rounded, label: 'Cases'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String route) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 25),
          
          // Grid for Stat Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.4,
            children: [
              _buildModernStatCard('Active', _alerts.length.toString(), Icons.warning_amber_rounded, Colors.orange),
              _buildModernStatCard('Pending', _alerts.where((a) => a.status == 'pending').length.toString(), Icons.hourglass_empty_rounded, Colors.blue),
              _buildModernStatCard('Resolved', _alerts.where((a) => a.status == 'resolved').length.toString(), Icons.check_circle_outline_rounded, Colors.green),
              _buildModernStatCard('Risk High', _alerts.where((a) => a.riskLevel == 'High').length.toString(), Icons.gpp_maybe_rounded, Colors.red),
            ],
          ),

          const SizedBox(height: 32),
          const _SectionLabel(label: 'Recent Critical Alerts'),
          const SizedBox(height: 16),

          if (_error != null)
            _buildErrorState()
          else if (_alerts.isEmpty)
            _buildEmptyState()
          else
            ..._alerts.take(5).map((alert) => _buildAlertTile(alert)),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duty Status: Active',
          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        const SizedBox(height: 4),
        const Text(
          'Officer Overview',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E)),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(CaseItem alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.bolt_rounded, color: Colors.orange),
        ),
        title: Text('Case #${alert.caseId}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Risk: ${alert.riskLevel}', style: TextStyle(color: alert.riskLevel == 'High' ? Colors.red : Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: alert.status == 'pending' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            alert.status.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: alert.status == 'pending' ? Colors.blue : Colors.green),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() => Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
  
  Widget _buildEmptyState() => const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('No alerts reported yet', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }
}