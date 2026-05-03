import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/portal_sound_service.dart';

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
        final alerts = await ApiService.getHospitalAlerts(token);
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
        if (alerts.isNotEmpty) {
          await PortalSoundService().playAlert();
        }
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
        title: 'Hospital Control Center',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.hospitalRequests);
          }
          if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.hospitalAmbulance);
          }
          if (index == 3) {
            Navigator.pushNamed(context, AppRoutes.hospitalSettings);
          }
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 18),
          const Text(
            'Emergency Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _buildStatCard('Active Requests', _alerts.length.toString(), Icons.emergency_share, AppColors.accent),
              _buildStatCard('Pending', _alerts.where((a) => a.status == 'pending').length.toString(), Icons.pending_actions_rounded, AppColors.success),
              _buildStatCard('Attended', _alerts.where((a) => a.status == 'attended').length.toString(), Icons.bed_rounded, AppColors.info),
              _buildStatCard('Critical', _alerts.where((a) => a.riskLevel == 'high').length.toString(), Icons.warning_amber_rounded, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Cases',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4),
              ),
              TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.hospitalRequests), child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Center(child: Text('Error: $_error'))
          else if (_alerts.isEmpty)
            _buildEmptyRequests()
          else
            ..._alerts.take(3).map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: alert.status == 'pending'
                                ? [AppColors.accent, AppColors.error]
                                : [AppColors.info, AppColors.primary],
                          ),
                        ),
                        child: const Icon(Icons.emergency_rounded, color: Colors.white),
                      ),
                      title: Text('Case ${alert.caseId}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${alert.status.toUpperCase()}  •  Risk: ${alert.riskLevel}', style: const TextStyle(fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(alert.status, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.user?.name.trim().isNotEmpty == true ? auth.user!.name.trim() : 'Hospital Team';
        final totalBeds = auth.user?.totalBeds ?? 0;
        final availableBeds = auth.user?.availableBeds ?? 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emergency Response Ready', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Hello, $name', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Monitor requests, manage ambulance flow, and respond fast.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _smallChip('Beds: $availableBeds/$totalBeds'),
                        _smallChip('Status: Active'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _smallChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _quickAction('Requests', Icons.emergency_rounded, AppRoutes.hospitalRequests, AppColors.accent),
        _quickAction('Ambulance', Icons.directions_car_rounded, AppRoutes.hospitalAmbulance, AppColors.success),
        _quickAction('Notifications', Icons.notifications_rounded, AppRoutes.hospitalNotifications, AppColors.info),
        _quickAction('Settings', Icons.settings_rounded, AppRoutes.hospitalSettings, AppColors.primary),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, String route, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequests() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 30),
            ),
            const SizedBox(height: 12),
            const Text('No emergency requests', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('The system is stable right now.', style: TextStyle(color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: AppColors.grey, fontSize: 14)),
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
