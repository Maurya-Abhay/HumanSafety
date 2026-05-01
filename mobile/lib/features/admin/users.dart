import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network_client.dart';
import 'dart:convert';
import 'dart:ui';

import '../../shared/widgets.dart';
import '../../core/routes.dart';
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
  String _searchQuery = ''; // Added search support

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => _isLoading = true);
      final token = await StorageService.getString(AppConstants.tokenKey);

      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/admin/users', options: Options(headers: {
        'Authorization': 'Bearer $token',
      }));

      if (resp.statusCode == 200) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        setState(() {
          _users = (data as Map<String, dynamic>)['users'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredUsers() {
    return _users.where((user) {
      final matchesRole = _roleFilter == 'all' || user['role'] == _roleFilter;
      final matchesSearch = user['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          user['phone'].toString().contains(_searchQuery);
      return matchesRole && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredUsers();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Community Directory',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Users', 'all'),
                      _buildFilterChip('Citizens', 'user'),
                      _buildFilterChip('Police Dept', 'police'),
                      _buildFilterChip('Medical', 'hospital'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Stats Brief (Optional but helpful for Admins)
          if (!_isLoading && _error == null)
            _buildStatsBar(filtered.length),

          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? _buildErrorState()
                    : filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => 
                                _buildUserCard(filtered[index]),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.adminReports);
          if (index == 3) Navigator.pushReplacementNamed(context, AppRoutes.adminAnalytics);
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.people_alt_rounded, label: 'Users'),
          BottomNavItem(icon: Icons.assignment_rounded, label: 'Reports'),
          BottomNavItem(icon: Icons.analytics_rounded, label: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search by name or phone...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) setState(() => _roleFilter = value);
        },
      ),
    );
  }

  Widget _buildStatsBar(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Text(
            'Showing $count members',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final isBlocked = user['isBlocked'] == true;
    final role = user['role'] ?? 'user';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildUserAvatar(user['name'] ?? 'U', role),
        title: Text(
          user['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user['phone'] ?? 'No Phone'),
            const SizedBox(height: 4),
            _buildRoleBadge(role),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBlocked ? Icons.block_flipped : Icons.check_circle_outline,
              color: isBlocked ? Colors.red : Colors.green,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              isBlocked ? 'Blocked' : 'Active',
              style: TextStyle(
                color: isBlocked ? Colors.red : Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  Widget _buildUserAvatar(String name, String role) {
    Color color;
    switch (role) {
      case 'police': color = Colors.blue; break;
      case 'hospital': color = Colors.redAccent; break;
      default: color = AppColors.primary;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey),
      ),
    );
  }

  // Error & Empty States
  Widget _buildErrorState() => Center(child: Text('Error: $_error'));
  Widget _buildEmptyState() => const Center(child: Text('No matching users found.'));

  void _showUserDetails(dynamic user) {
    final isBlocked = user['isBlocked'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              _buildUserAvatar(user['name'], user['role']),
              const SizedBox(height: 12),
              Text(user['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(user['email'] ?? 'No email provided', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              const Divider(),
              _buildDetailRow('Phone Number', user['phone'] ?? 'N/A'),
              _buildDetailRow('Account Type', user['role']?.toUpperCase() ?? 'USER'),
              _buildDetailRow('Registration Date', user['createdAt']?.split('T')[0] ?? 'N/A'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleBlockUser(user['_id']);
                      },
                      child: Text(isBlocked ? 'Unblock User' : 'Block User'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _toggleBlockUser(String userId) async {
    final token = await StorageService.getString(AppConstants.tokenKey);
    if (token == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    final userIndex = _users.indexWhere((u) => u['_id'] == userId);
    if (userIndex == -1) return;

    final user = _users[userIndex];
    final currentlyBlocked = user['isBlocked'] == true;

    // If we're blocking, ask for a reason
    String? reason;
    if (!currentlyBlocked) {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Block user'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Reason for blocking'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Block')),
            ],
          );
        },
      );

      if (reason == null || reason.isEmpty) {
        // user cancelled or did not provide reason
        return;
      }
    }

    try {
      setState(() => _isLoading = true);
      final dio = NetworkClient().client;
      final endpoint = currentlyBlocked ? '/api/v1/admin/users/$userId/unblock' : '/api/v1/admin/users/$userId/block';
      final data = currentlyBlocked ? {} : { 'blockReason': reason };

      final resp = await dio.post(endpoint, data: data, options: Options(headers: {
        'Authorization': 'Bearer $token',
      }));

      if (resp.statusCode == 200) {
        // Update local state
        setState(() {
          _users[userIndex]['isBlocked'] = !currentlyBlocked;
          if (!currentlyBlocked) {
            _users[userIndex]['blockReason'] = reason;
          } else {
            _users[userIndex]['blockReason'] = null;
          }
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentlyBlocked ? 'User unblocked' : 'User blocked')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action failed')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}