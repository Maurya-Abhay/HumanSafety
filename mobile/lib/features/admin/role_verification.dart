import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/network_client.dart';
import 'dart:convert';
import 'dart:ui';

import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class RoleVerificationScreen extends StatefulWidget {
  const RoleVerificationScreen({super.key});

  @override
  State<RoleVerificationScreen> createState() => _RoleVerificationScreenState();
}

class _RoleVerificationScreenState extends State<RoleVerificationScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/admin/role-applications', queryParameters: {'status': _filterStatus}, options: Options(headers: {
        'Authorization': 'Bearer $token',
      }));

      if (resp.statusCode == 200) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        setState(() {
          _applications = (data as Map<String, dynamic>)['applications'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) _showToast('Failed to fetch data', Colors.red);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) _showToast('Error: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Role Verification',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminProfile),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminSettings),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: _Blob(
                color: AppColors.primary.withValues(alpha: 0.1), size: 300),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              _buildFilterBar(theme),
              Expanded(
                child: _isLoading
                    ? const Center(child: LoadingWidget())
                    : _applications.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchApplications,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _applications.length,
                              itemBuilder: (context, index) =>
                                  _buildModernApplicationCard(
                                      _applications[index], theme),
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0)
            Navigator.pushNamed(context, AppRoutes.adminDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.adminUsers);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.adminReports);
          if (index == 3)
            Navigator.pushNamed(context, AppRoutes.adminAnalytics);
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

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildChip('Pending', 'pending', Colors.orange),
          const SizedBox(width: 8),
          _buildChip('Approved', 'approved', Colors.green),
          const SizedBox(width: 8),
          _buildChip('Rejected', 'rejected', Colors.red),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String status, Color color) {
    final isSelected = _filterStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filterStatus = status);
          _fetchApplications();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernApplicationCard(dynamic app, ThemeData theme) {
    final role = app['requestedRole']?.toString().toLowerCase() ?? 'user';
    final roleIcon = role == 'police'
        ? Icons.security_rounded
        : Icons.medical_services_rounded;
    final accentColor = role == 'police' ? Colors.blueAccent : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: InkWell(
        onTap: () => _showApplicationDetails(app),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    child: Icon(roleIcon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app['applicantName'] ?? 'Unknown Applicant',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          app['applicantPhone'] ?? 'No contact info',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.grey.withValues(alpha: 0.5)),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoleBadge(label: role.toUpperCase(), color: accentColor),
                  Text(
                    'Tap to verify documents',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Bottom Nav Consistent with other screens ---
  Widget _buildPremiumNav(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.dashboard_rounded, AppRoutes.adminDashboard, false),
          _navIcon(Icons.people_alt_rounded, AppRoutes.adminUsers, true),
          _navIcon(Icons.assignment_rounded, AppRoutes.adminReports, false),
          _navIcon(Icons.insights_rounded, AppRoutes.adminAnalytics, false),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String route, bool isSelected) {
    return GestureDetector(
      onTap: () => isSelected ? null : Navigator.pushNamed(context, route),
      child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 80, color: AppColors.grey),
          SizedBox(height: 16),
          Text('No pending verifications',
              style: TextStyle(color: AppColors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  void _showApplicationDetails(dynamic app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApplicationDetailsSheet(
        application: app,
        onApprove: () => _approveApplication(app['_id']),
        onReject: () => _showRejectDialog(app['_id']),
      ),
    );
  }

  // ... (Keeping _approveApplication and _rejectApplication logic same as user provided) ...
  // --- logic same as above ---
  Future<void> _approveApplication(String appId) async {
    try {
      setState(() => _isLoading = true);
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      final dio = NetworkClient().client;

      final resp = await dio.post('/api/v1/admin/role-applications/$appId/approve', data: {}, options: Options(headers: {
        'Authorization': 'Bearer $token',
      }));

      if (resp.statusCode == 200) {
        _showToast('Application approved', Colors.green);
        await _fetchApplications();
      } else {
        _showToast('Approval failed', Colors.red);
      }
    } catch (e) {
      _showToast('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(String appId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            final reason = controller.text.trim();
            Navigator.pop(ctx);
            if (reason.isNotEmpty) _rejectApplication(appId, reason);
            else _showToast('Please provide a reason', Colors.orange);
          }, child: const Text('Reject')),
        ],
      ),
    );
  }

  Future<void> _rejectApplication(String appId, String notes) async {
    try {
      setState(() => _isLoading = true);
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      final dio = NetworkClient().client;

      final resp = await dio.post('/api/v1/admin/role-applications/$appId/reject', data: { 'rejectionReason': notes }, options: Options(headers: {
        'Authorization': 'Bearer $token',
      }));

      if (resp.statusCode == 200) {
        _showToast('Application rejected', Colors.green);
        await _fetchApplications();
      } else {
        _showToast('Rejection failed', Colors.red);
      }
    } catch (e) {
      _showToast('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _ApplicationDetailsSheet extends StatelessWidget {
  final dynamic application;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationDetailsSheet(
      {required this.application,
      required this.onApprove,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = application['status'] ?? 'pending';
    final isPending = status == 'pending';
    final role = (application['requestedRole'] ?? 'police').toString();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Verification Details',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  _RoleBadge(
                      label: status.toUpperCase(),
                      color:
                          status == 'approved' ? Colors.green : Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoTile('Full Name', application['applicantName'] ?? 'N/A',
                  Icons.person_outline),
              _buildInfoTile('Email Address',
                  application['applicantEmail'] ?? 'N/A', Icons.email_outlined),
              _buildInfoTile('Contact', application['applicantPhone'] ?? 'N/A',
                  Icons.phone_outlined),
              const Divider(height: 32),
              Text('${role.toUpperCase()} CREDENTIALS',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                      letterSpacing: 1)),
              const SizedBox(height: 16),
              if (role == 'police') ...[
                _buildInfoTile('Badge Number',
                    application['badgeNumber'] ?? 'N/A', Icons.badge_outlined),
                _buildInfoTile(
                    'Police Station',
                    application['stationName'] ?? 'N/A',
                    Icons.local_police_outlined),
                _buildInfoTile('Station Address',
                    application['stationAddress'] ?? 'N/A', Icons.map_outlined),
              ] else ...[
                _buildInfoTile(
                    'Hospital Name',
                    application['hospitalName'] ?? 'N/A',
                    Icons.local_hospital_outlined),
                _buildInfoTile(
                    'Medical Staff Type',
                    (application['staffType'] ?? 'N/A')
                        .toString()
                        .toUpperCase(),
                    Icons.medical_information_outlined),
                _buildInfoTile(
                    'Hospital Address',
                    application['hospitalAddress'] ?? 'N/A',
                    Icons.location_on_outlined),
              ],
              const SizedBox(height: 32),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                          label: 'REJECT',
                          color: Colors.red,
                          icon: Icons.close,
                          onTap: onReject),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionButton(
                          label: 'APPROVE',
                          color: Colors.green,
                          icon: Icons.check,
                          onTap: onApprove),
                    ),
                  ],
                )
              else
                Center(
                    child: Text('Request already processed.',
                        style: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Premium Support Widgets ---

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(colors: [color, color.withValues(alpha: 0)])));
}

extension StringExt on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
