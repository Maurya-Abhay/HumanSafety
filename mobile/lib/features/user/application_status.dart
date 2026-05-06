import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/network_client.dart';
import 'dart:convert';

import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  bool _isLoading = true;
  dynamic _applicationData;

  @override
  void initState() {
    super.initState();
    _fetchApplicationDetails();
  }

  Future<void> _fetchApplicationDetails() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      final dio = NetworkClient().client;

      final resp = await dio.get(
        '/api/v1/user/application-details',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (resp.statusCode == 200) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        setState(() {
          _applicationData = data['data'] ?? data;
          _isLoading = false;
        });
      } else {
        _showToast('Failed to fetch application details', Colors.red);
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Application Status',
          showBackButton: true,
        ),
        body: const Center(child: LoadingWidget()),
      );
    }

    if (_applicationData == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Application Status', showBackButton: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 60, color: AppColors.grey),
              const SizedBox(height: 16),
              const Text('No active application',
                  style: TextStyle(color: AppColors.grey)),
            ],
          ),
        ),
      );
    }

    final role = _applicationData['role'] ?? 'user';
    final status = _applicationData['status'] ?? 'pending';
    final steps = (_applicationData['steps'] ?? []) as List;
    final completedSteps = _applicationData['completedSteps'] ?? 0;
    final totalSteps = _applicationData['totalSteps'] ?? 4;
    final currentStep = _applicationData['currentStep'];
    final rejectionReason = _applicationData['rejectionReason'];
    final allApproved = _applicationData['allApproved'] ?? false;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Application Status',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: allApproved
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : status == 'rejected'
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            allApproved
                                ? '✓ APPROVED'
                                : status == 'rejected'
                                    ? '✗ REJECTED'
                                    : 'IN REVIEW',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        allApproved
                            ? Icons.check_circle
                            : status == 'rejected'
                                ? Icons.cancel
                                : Icons.schedule,
                        size: 50,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  if (!allApproved && completedSteps > 0) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completedSteps / totalSteps,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedSteps of $totalSteps steps completed',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Rejection Reason
            if (rejectionReason != null && rejectionReason.toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Rejection Reason',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rejectionReason,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Verification Steps
            const Text(
              'Verification Steps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final stepStatus = step['status'] ?? 'pending';
              final stepLabel = step['label'] ?? 'Step ${index + 1}';
              final stepNotes = step['notes'] ?? '';

              Color statusColor;
              IconData statusIcon;

              if (stepStatus == 'approved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (stepStatus == 'rejected') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              } else {
                statusColor = Colors.orange;
                statusIcon = Icons.schedule;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: statusColor.withValues(alpha: 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Icon(statusIcon, color: statusColor, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stepLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                stepStatus.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (stepNotes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Admin Notes: $stepNotes',
                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Timeline
            if (allApproved)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green),
                        const SizedBox(width: 12),
                        const Text(
                          'Verification Complete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your role has been verified and activated. You now have full access to ${role.toUpperCase()} features.',
                      style: const TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
