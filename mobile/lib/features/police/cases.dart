import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  late String _token;
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = false;
  String _statusFilter = 'all';
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
        // TODO: Integrate with actual API
        final cases = <Map<String, dynamic>>[
          {
            'id': '507f1f77bcf86cd799439011',
            'status': 'pending',
            'description': 'Traffic Accident on Highway',
            'location': 'Main Street, Downtown',
            'riskLevel': 'HIGH',
          },
          {
            'id': '507f1f77bcf86cd799439012',
            'status': 'in-progress',
            'description': 'Medical Emergency',
            'location': 'Hospital Rd, Sector 5',
            'riskLevel': 'MEDIUM',
          },
        ];
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

  Future<void> _updateCaseStatus(String caseId, String newStatus) async {
    try {
      // TODO: Call API to update status
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Case status updated to $newStatus')),
      );
      _loadCases();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredCases() {
    if (_statusFilter == 'all') return _cases;
    return _cases.where((c) => (c['status'] as String).toLowerCase() == _statusFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredCases();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'My Cases',
        showBackButton: false,
        actions: [
          _buildActionCircle(Icons.notifications_none_rounded, AppRoutes.policeNotifications),
          _buildActionCircle(Icons.person_outline_rounded, AppRoutes.policeProfile),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _cases.isEmpty
                    ? _buildEmptyView()
                    : Column(
                        children: [
                          _buildFilterChips(),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => _buildCaseCard(filtered[index]),
                            ),
                          ),
                        ],
                      ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.policeDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.policeAlerts);
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

  Widget _buildFilterChips() {
    final filters = ['all', 'pending', 'in-progress', 'resolved'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _statusFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter == 'all' ? 'All Cases' : filter.replaceFirst(filter[0], filter[0].toUpperCase())),
              selected: isSelected,
              onSelected: (_) => setState(() => _statusFilter = filter),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final statusStr = (caseData['status'] as String?) ?? 'pending';
    final statusColor = _getStatusColor(statusStr);
    final caseId = (caseData['id'] as String?) ?? 'N/A';
    final displayId = caseId.length > 24 ? caseId.substring(18, 24).toUpperCase() : caseId.substring(0, 6).toUpperCase();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCaseDetails(caseData),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case #$displayId',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (caseData['description'] as String?) ?? 'Emergency Response',
                          style: const TextStyle(fontSize: 13, color: AppColors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusStr.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCaseInfo(Icons.location_on_outlined, (caseData['location'] as String?) ?? 'Unknown', AppColors.grey),
                  _buildCaseInfo(Icons.priority_high_rounded, (caseData['riskLevel'] as String?) ?? 'NORMAL', _getRiskColor((caseData['riskLevel'] as String?) ?? 'NORMAL')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateCaseStatus(caseId, 'in-progress'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accept', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateCaseStatus(caseId, 'resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  void _showCaseDetails(Map<String, dynamic> caseData) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Case Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Case ID', ((caseData['id'] as String?) ?? 'N/A').substring(0, 8)),
            _detailRow('Status', ((caseData['status'] as String?) ?? 'pending').toUpperCase()),
            _detailRow('Risk Level', (caseData['riskLevel'] as String?) ?? 'NORMAL'),
            _detailRow('Location', (caseData['location'] as String?) ?? 'Unknown'),
            _detailRow('Description', (caseData['description'] as String?) ?? 'N/A'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String route) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadCases, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_rounded, size: 64, color: AppColors.grey),
          const SizedBox(height: 16),
          const Text('No cases assigned yet', style: TextStyle(color: AppColors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadCases, child: const Text('Check for Cases')),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
