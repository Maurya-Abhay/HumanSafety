import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/widgets.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      setState(() => _isLoading = true);
      final token = await StorageService.getString(AppConstants.tokenKey);
      
      // Fetch cases/emergencies as reports
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/v1/cases/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reports = data['cases'] ?? data ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch reports';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredReports() {
    if (_statusFilter == 'all') return _reports;
    return _reports.where((r) => r['status'] == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredReports();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reports'),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Pending', 'pending'),
                  _buildFilterChip('Active', 'active'),
                  _buildFilterChip('Resolved', 'resolved'),
                ],
              ),
            ),
          ),
          // Reports list
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : filtered.isEmpty
                        ? const Center(child: Text('No reports found'))
                        : RefreshIndicator(
                            onRefresh: _fetchReports,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final report = filtered[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildReportCard(report),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  Widget _buildReportCard(dynamic report) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  report['title'] ?? report['description'] ?? 'Emergency Case',
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(report['status']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report['status']?.toString().toUpperCase() ?? 'PENDING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report['description'] ?? 'No description',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${report['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Priority: ${report['priority']?.toString().toUpperCase() ?? 'MEDIUM'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.red;
      case 'resolved':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }
}
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
