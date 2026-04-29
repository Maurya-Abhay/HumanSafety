import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart'; // CaseItem model yahan se aayega
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';

// --- ALERTS SCREEN (MODERNIZED) ---
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late String _token;
  List<CaseItem> _cases = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      if (_token.isNotEmpty) {
        final cases = await ApiService.getPoliceAlerts(_token);
        if (mounted) {
          setState(() {
            _cases = cases;
            _error = null;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptCase(String caseId) async {
    try {
      await ApiService.acceptEmergency(_token, caseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Case accepted successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadAlerts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Emergency Alerts',
        showBackButton: false,
        actions: [
          _buildActionCircle(Icons.notifications_none_rounded, AppRoutes.policeNotifications),
          _buildActionCircle(Icons.person_outline_rounded, AppRoutes.policeProfile),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _cases.isEmpty
                    ? _buildEmptyView()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _cases.length,
                        itemBuilder: (context, index) => _buildAlertCard(_cases[index]),
                      ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildActionCircle(IconData icon, String route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildAlertCard(CaseItem caseItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: _getPriorityColor(caseItem.riskLevel), width: 6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(caseItem.description ?? 'High Priority Alert',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    _buildRiskChip(caseItem.riskLevel),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(caseItem.location?['address'] ?? 'Fetching location...',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${caseItem.status.toUpperCase()}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      onPressed: () => _acceptCase(caseItem.id),
                      child: const Text('Accept Call', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String? risk) {
    if (risk == 'High') return Colors.redAccent;
    if (risk == 'Medium') return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  Widget _buildRiskChip(String? risk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(risk).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(risk ?? 'Low', 
        style: TextStyle(color: _getPriorityColor(risk), fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildEmptyView() => const Center(child: Text('No active alerts at the moment', style: TextStyle(color: Colors.grey)));
  Widget _buildErrorView() => Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)));
}

// --- CASES SCREEN (REFINED) ---
class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  late String _token;
  List<CaseItem> _cases = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      if (_token.isNotEmpty) {
        final cases = await ApiService.getPoliceAlerts(_token);
        if (mounted) {
          setState(() {
            _cases = cases;
            _error = null;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String caseId, String status) async {
    try {
      await ApiService.updateCaseStatus(_token, caseId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status: $status'), backgroundColor: AppColors.primary));
      _loadCases();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(title: 'Active Cases', showBackButton: false),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cases.isEmpty
                ? const Center(child: Text('No assigned cases found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _cases.length,
                    itemBuilder: (context, index) => _buildCaseCard(_cases[index]),
                  ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildCaseCard(CaseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.assignment_rounded, color: AppColors.primary),
        ),
        title: Text(item.description ?? 'Police Case', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Status: ${item.status}', style: TextStyle(color: Colors.grey.shade600)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (val) => _updateStatus(item.id, val),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'in-progress', child: Text('In Progress')),
            const PopupMenuItem(value: 'resolved', child: Text('Mark Resolved')),
            const PopupMenuItem(value: 'closed', child: Text('Close Case')),
          ],
        ),
      ),
    );
  }
}

// --- HELPER FOR BOTTOM NAV ---
Widget _buildBottomNav(BuildContext context, int index) {
  return CustomBottomNav(
    currentIndex: index,
    onTap: (i) {
      if (i == index) return;
      if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.policeDashboard);
      if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.policeAlerts);
      if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.policeCases);
      if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.policeSettings);
    },
    items: const [
      BottomNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
      BottomNavItem(icon: Icons.bolt_rounded, label: 'Alerts'),
      BottomNavItem(icon: Icons.assignment_rounded, label: 'Cases'),
      BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ],
  );
}
