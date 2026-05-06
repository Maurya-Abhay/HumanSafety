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

class RoleVerificationStepsScreen extends StatefulWidget {
  final String applicationId;
  final VoidCallback onBackRequested;

  const RoleVerificationStepsScreen(
      {required this.applicationId, required this.onBackRequested});

  @override
  State<RoleVerificationStepsScreen> createState() =>
      _RoleVerificationStepsScreenState();
}

class _RoleVerificationStepsScreenState
    extends State<RoleVerificationStepsScreen> {
  bool _isLoading = true;
  dynamic _verificationDetails;
  final List<String> _steps = [
    'documentVerification',
    'addressVerification',
    'credentialsVerification',
    'backgroundCheck',
  ];

  @override
  void initState() {
    super.initState();
    _fetchVerificationDetails();
  }

  Future<void> _fetchVerificationDetails() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      final dio = NetworkClient().client;

      final resp = await dio.get(
        '/api/v1/admin/role-applications/${widget.applicationId}/details',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (resp.statusCode == 200) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        setState(() {
          _verificationDetails = data;
          _isLoading = false;
        });
      } else {
        _showToast('Failed to fetch details', Colors.red);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showToast('Error: $e', Colors.red);
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

  Future<void> _approveStep(String step) async {
    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve $step'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Add notes (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Approve')),
        ],
      ),
    );

    if (notes != null) {
      try {
        final authProvider = context.read<AuthProvider>();
        final token = authProvider.token;
        final dio = NetworkClient().client;

        final resp = await dio.post(
          '/api/v1/admin/role-applications/${widget.applicationId}/verify/$step/approve',
          data: {'notes': notes},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (resp.statusCode == 200) {
          _showToast('Step approved', Colors.green);
          await _fetchVerificationDetails();
        } else {
          _showToast('Approval failed', Colors.red);
        }
      } catch (e) {
        _showToast('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _rejectStep(String step) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject $step'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Rejection reason (required)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: controller.text.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, controller.text),
              child: const Text('Reject')),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final authProvider = context.read<AuthProvider>();
        final token = authProvider.token;
        final dio = NetworkClient().client;

        final resp = await dio.post(
          '/api/v1/admin/role-applications/${widget.applicationId}/verify/$step/reject',
          data: {'notes': reason},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (resp.statusCode == 200) {
          _showToast('Step rejected', Colors.green);
          await _fetchVerificationDetails();
        } else {
          _showToast('Rejection failed', Colors.red);
        }
      } catch (e) {
        _showToast('Error: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    final steps = _verificationDetails['steps'] ?? {};
    final userStatus = _verificationDetails['status'] ?? 'pending';
    final role = _verificationDetails['role'] ?? 'user';

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Verification Steps',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: userStatus == 'active'
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(userStatus.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_verificationDetails['name']} (${role.toUpperCase()})',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Steps List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _buildStepCards(steps),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStepCards(Map<String, dynamic> steps) {
    final stepTitles = {
      'documentVerification': '📄 Document Verification',
      'addressVerification': '📍 Address Verification',
      'credentialsVerification': '🎖️ Credentials Verification',
      'backgroundCheck': '🔍 Background Check',
    };

    return _steps.asMap().entries.map((entry) {
      final index = entry.key;
      final stepKey = entry.value;
      final stepData = steps[stepKey] ?? {};
      final status = stepData['status'] ?? 'pending';
      final description = stepData['description'] ?? '';

      Color statusColor;
      IconData statusIcon;
      bool isPending = status == 'pending';

      if (status == 'approved') {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else if (status == 'rejected') {
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: InkWell(
          onTap: isPending
              ? () => _showStepDetails(stepKey, stepData)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Step Number
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Icon(statusIcon,
                            color: statusColor, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stepTitles[stepKey] ?? stepKey,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(description,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey
                                      .withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(status.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (stepData['notes'] != null &&
                    stepData['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Notes: ${stepData['notes']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey)),
                  ),
                ],
                if (isPending) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectStep(stepKey),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveStep(stepKey),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showStepDetails(String stepKey, dynamic stepData) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Step Details',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (stepData['documents'] != null) ...[
                const Text('Documents',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...(stepData['documents'] as Map).entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${e.key}: ${e.value ?? 'N/A'}')),
                        ],
                      ),
                    )),
              ],
              if (stepData['address'] != null) ...[
                const Text('Address',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(stepData['address'] ?? 'N/A'),
              ],
              if (stepData['details'] != null) ...[
                const Text('Details',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...(stepData['details'] as Map).entries.map((e) => Text(
                    '${e.key}: ${e.value ?? 'N/A'}')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
