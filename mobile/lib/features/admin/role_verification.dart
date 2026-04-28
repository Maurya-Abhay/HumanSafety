import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/api_service.dart';

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

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/v1/admin/role-applications?status=$_filterStatus'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _applications = data['applications'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch applications')),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Role Verification',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterTab('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterTab('Approved', 'approved'),
                const SizedBox(width: 8),
                _buildFilterTab('Rejected', 'rejected'),
              ],
            ),
          ),
          // Applications list
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _applications.isEmpty
                    ? const Center(child: Text('No applications found'))
                    : RefreshIndicator(
                        onRefresh: _fetchApplications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _applications.length,
                          itemBuilder: (context, index) {
                            final app = _applications[index];
                            return _buildApplicationCard(app);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String status) {
    final isActive = _filterStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filterStatus = status);
          _fetchApplications();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(dynamic app) {
    final status = app['status'] ?? 'pending';
    final statusColor = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return CustomCard(
      onTap: () => _showApplicationDetails(app),
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
                      app['applicantName'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app['applicantPhone'] ?? '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  app['requestedRole']?.toUpperCase() ?? 'UNKNOWN',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ${status.capitalize()}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tap for details',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApplicationDetails(dynamic app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ApplicationDetailsSheet(
        application: app,
        onApprove: () => _approveApplication(app['_id']),
        onReject: () => _showRejectDialog(app['_id']),
      ),
    );
  }

  Future<void> _approveApplication(String appId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/admin/role-applications/$appId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'approvalNotes': 'Approved',
        }),
      );

      if (mounted) {
        Navigator.pop(context); // Close details sheet
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application approved!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchApplications();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to approve application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String appId) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter reason...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectApplication(appId, notesController.text);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectApplication(String appId, String notes) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/admin/role-applications/$appId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rejectionReason': notes.isNotEmpty ? notes : 'Application rejected by admin',
        }),
      );

      if (mounted) {
        Navigator.pop(context);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application rejected'),
              backgroundColor: Colors.red,
            ),
          );
          _fetchApplications();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ApplicationDetailsSheet extends StatelessWidget {
  final dynamic application;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationDetailsSheet({
    required this.application,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = application['status'] ?? 'pending';
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application['applicantName'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      application['applicantEmail'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'approved'
                        ? Colors.green.withValues(alpha: 0.2)
                        : status == 'rejected'
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.capitalize(),
                    style: TextStyle(
                      color: status == 'approved'
                          ? Colors.green
                          : status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Role Info
            _buildDetailSection(
              'Applied Role',
              application['requestedRole']?.toUpperCase() ?? 'UNKNOWN',
              Icons.badge,
            ),
            const SizedBox(height: 16),

            // Applicant Contact
            _buildDetailSection(
              'Phone',
              application['applicantPhone'] ?? 'N/A',
              Icons.phone,
            ),
            const SizedBox(height: 16),

            // Role-specific details
            if (application['requestedRole'] == 'police') ...[
              _buildDetailSection(
                'Badge Number',
                application['badgeNumber'] ?? 'N/A',
                Icons.badge,
              ),
              const SizedBox(height: 16),
              _buildDetailSection(
                'Station Name',
                application['stationName'] ?? 'N/A',
                Icons.location_city,
              ),
              const SizedBox(height: 16),
              _buildDetailSection(
                'Station Address',
                application['stationAddress'] ?? 'N/A',
                Icons.location_on,
              ),
            ] else ...[
              _buildDetailSection(
                'Hospital Name',
                application['hospitalName'] ?? 'N/A',
                Icons.local_hospital,
              ),
              const SizedBox(height: 16),
              _buildDetailSection(
                'Hospital Address',
                application['hospitalAddress'] ?? 'N/A',
                Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildDetailSection(
                'Staff Type',
                (application['staffType'] ?? 'N/A').capitalize(),
                Icons.person,
              ),
            ],

            if (!isPending) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                'Verified By',
                application['verifiedBy']?.toString() ?? 'Admin',
                Icons.verified_user,
              ),
              const SizedBox(height: 16),
              _buildDetailSection(
                'Notes',
                application['adminNotes'] ?? 'N/A',
                Icons.note,
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Text(
                  'Already ${status.capitalize()}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension StringExt on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
