import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/widgets.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => _isLoading = true);
      final token = await StorageService.getString(AppConstants.tokenKey);
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/v1/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = data['users'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch users';
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

  List<dynamic> _getFilteredUsers() {
    if (_roleFilter == 'all') return _users;
    return _users.where((u) => u['role'] == _roleFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredUsers();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Users'),
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
                  _buildFilterChip('Users', 'user'),
                  _buildFilterChip('Police', 'police'),
                  _buildFilterChip('Hospital', 'hospital'),
                ],
              ),
            ),
          ),
          // Users list
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : filtered.isEmpty
                        ? const Center(child: Text('No users found'))
                        : RefreshIndicator(
                            onRefresh: _fetchUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final user = filtered[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildUserCard(user),
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
    final isSelected = _roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _roleFilter = value),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    return CustomCard(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Center(
            child: Text(
              (user['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        title: Text(user['name'] ?? 'Unknown'),
        subtitle: Text('${user['phone'] ?? 'N/A'} • ${user['role'] ?? 'user'}'),
        trailing: Chip(
          label: Text(user['isBlocked'] == true ? 'Blocked' : 'Active'),
          backgroundColor: user['isBlocked'] == true ? Colors.red : AppColors.success,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  void _showUserDetails(dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User Details', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildDetailRow('Name', user['name'] ?? 'N/A'),
            _buildDetailRow('Phone', user['phone'] ?? 'N/A'),
            _buildDetailRow('Email', user['email'] ?? 'N/A'),
            _buildDetailRow('Role', user['role'] ?? 'user'),
            _buildDetailRow('Status', user['isBlocked'] == true ? 'Blocked' : 'Active'),
            _buildDetailRow('Joined', user['createdAt']?.split('T')[0] ?? 'N/A'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: user['isBlocked'] == true ? 'Unblock' : 'Block',
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleBlockUser(user['_id']);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _toggleBlockUser(String userId) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      final action = _users.firstWhere((u) => u['_id'] == userId)['isBlocked'] == true ? 'unblock' : 'block';
      
      final endpoint = '${ApiService.baseUrl}/api/v1/admin/users/$userId/${action}';
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'blockReason': 'Admin action'}),
      );

      if (response.statusCode == 200) {
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User ${action}ed successfully')),
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
}
