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
  final int _currentIndex = 0; // Current index for dashboard
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
        if (!mounted) return;
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
        if (alerts.isNotEmpty) {
          await PortalSoundService().playAlert();
        }
      } else {
        if (!mounted) return;
        setState(() {
          _error = "Authentication token not found.";
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        centerTitle: false,
        title: Text(
          'Hospital Control Center',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : const Color(0xFF475569)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: Icon(Icons.person_outline_rounded, color: isDark ? Colors.white : const Color(0xFF475569)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        color: const Color(0xFF2563EB),
        child: _buildBody(isDark),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalRequests);
          }
          if (index == 2) {
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalAmbulance);
          }
          if (index == 3) {
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalSettings);
          }
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency_rounded, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car_rounded, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(isDark),
          const SizedBox(height: 24),
          _buildSectionHeader('Quick Management Actions'),
          const SizedBox(height: 12),
          _buildQuickActions(isDark),
          const SizedBox(height: 24),
          _buildSectionHeader('Emergency Department Status'),
          const SizedBox(height: 12),
          _buildStatGrid(isDark),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Recent Active Cases'),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.hospitalRequests),
                icon: const Text('View All', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                label: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCaseSection(isDark),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.user?.name.trim().isNotEmpty == true ? auth.user!.name.trim() : 'Hospital Team';
        final totalBeds = auth.user?.totalBeds ?? 0;
        final availableBeds = auth.user?.availableBeds ?? 0;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMERGENCY RESPONSE READY',
                      style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hello, $name',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Monitor active requests and manage live routing.',
                      style: TextStyle(color: AppColors.whiteBorders, fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _smallChip('Beds: $availableBeds/$totalBeds', Icons.bed_rounded),
                        _smallChip('Status: Active', Icons.check_circle_rounded),
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

  Widget _smallChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 12,
      childAspectRatio: 2.3,
      children: [
        _quickAction('Case Logs', Icons.emergency_rounded, AppRoutes.hospitalRequests, const Color(0xFFEF4444), isDark),
        _quickAction('Ambulance', Icons.directions_car_rounded, AppRoutes.hospitalAmbulance, const Color(0xFF10B981), isDark),
        _quickAction('Alerts Inbox', Icons.notifications_rounded, AppRoutes.hospitalNotifications, const Color(0xFF3B82F6), isDark),
        _quickAction('Settings', Icons.settings_rounded, AppRoutes.hospitalSettings, const Color(0xFF6366F1), isDark),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, String route, Color color, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(isDark ? 0.08 : 0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(bool isDark) {
    final active = _alerts.length;
    final pending = _alerts.where((a) => a.status == 'pending').length;
    final attended = _alerts.where((a) => a.status == 'attended').length;
    final critical = _alerts.where((a) => a.riskLevel == 'high').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildStatCard('Active Request', active.toString(), Icons.emergency_share_rounded, const Color(0xFFF97316), isDark),
        _buildStatCard('Pending Response', pending.toString(), Icons.pending_actions_rounded, const Color(0xFF10B981), isDark),
        _buildStatCard('Attended Live', attended.toString(), Icons.bed_rounded, const Color(0xFF3B82F6), isDark),
        _buildStatCard('High Risk Alert', critical.toString(), Icons.warning_amber_rounded, const Color(0xFFEF4444), isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(isDark ? 0.08 : 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseSection(bool isDark) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    } else if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444))),
        ),
      );
    } else if (_alerts.isEmpty) {
      return _buildEmptyRequests(isDark);
    }

    return Column(
      children: _alerts.take(3).map((alert) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(isDark ? 0.08 : 0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: alert.status == 'pending'
                    ? [const Color(0xFFEF4444), const Color(0xFFF97316)]
                    : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
            ),
            child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
          ),
          title: Text(
            'Case ID: #${alert.caseId}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          subtitle: Text(
            'Risk level: ${alert.riskLevel.toUpperCase()}',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: alert.status == 'pending' ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: alert.status == 'pending' ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE)),
            ),
            child: Text(
              alert.status.toUpperCase(),
              style: TextStyle(
                color: alert.status == 'pending' ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyRequests(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'No Active Emergencies',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'System is monitored and currently stable.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// (removed invalid Colors extension) Using `AppColors.whiteBorders` from core/theme.dart