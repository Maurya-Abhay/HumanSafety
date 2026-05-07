import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/api_service.dart';

class AmbulanceProfileScreen extends StatefulWidget {
  const AmbulanceProfileScreen({super.key});

  @override
  State<AmbulanceProfileScreen> createState() => _AmbulanceProfileScreenState();
}

class _AmbulanceProfileScreenState extends State<AmbulanceProfileScreen> {
  // Profile is index 3 in our footer
  final int _currentIndex = 3;
  bool _isUpdatingProfile = false;

  Future<void> _showEditProfileDialog(AuthProvider authProvider) async {
    final user = authProvider.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final addressController = TextEditingController(text: user.address ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated != true) return;

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }

    if (authProvider.token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    try {
      setState(() => _isUpdatingProfile = true);
      await ApiService.updateProfile(authProvider.token!, {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
      });
      await authProvider.fetchUserProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingProfile = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AmbulanceProvider>().loadProfileStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Driver Profile',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.ambulanceNotifications);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              // Add your logout logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logging out...')),
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, AmbulanceProvider>(
        builder: (context, authProvider, ambulanceProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // --- PROFILE HEADER ---
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.blue.shade400, width: 3),
                            ),
                            child: const CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person,
                                  size: 60, color: Colors.blue),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.green, shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'Driver Name',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.phone ?? '+91 XXXXX-XXXXX',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- STATISTICS ROW ---
                Row(
                  children: [
                    _buildStatCard(
                        context,
                        'Total Trips',
                        ambulanceProvider.totalTrips.toString(),
                        Icons.local_shipping_rounded,
                        Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard(
                        context,
                        'Rating',
                        '${ambulanceProvider.averageRating.toStringAsFixed(1)} ★',
                        Icons.star_rounded,
                        Colors.orange),
                  ],
                ),

                const SizedBox(height: 30),

                // --- ACTION LIST ---
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileTile(
                          Icons.edit_note_rounded, 'Edit Profile Information',
                          () {
                        if (_isUpdatingProfile) return;
                        _showEditProfileDialog(authProvider);
                      }),
                      const Divider(height: 1),
                      _buildProfileTile(Icons.history_rounded, 'Ride History',
                          () {
                        Navigator.pushNamed(
                            context, AppRoutes.ambulanceHistory);
                      }),
                      const Divider(height: 1),
                      _buildProfileTile(Icons.verified_user_rounded,
                          'License & Documents', () {}),
                      const Divider(height: 1),
                      _buildProfileTile(
                          Icons.settings_suggest_rounded, 'App Settings', () {
                        Navigator.pushNamed(
                            context, AppRoutes.ambulanceSettings);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),

      // --- FOOTER (BOTTOM NAV) ---
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.ambulanceHome);
              break;
            case 1:
              Navigator.pushReplacementNamed(
                  context, AppRoutes.ambulanceRequests);
              break;
            case 2:
              final hasActiveMission =
                  context.read<AmbulanceProvider>().currentAssignment != null;
              Navigator.pushReplacementNamed(
                context,
                hasActiveMission
                    ? AppRoutes.ambulanceCurrentCase
                    : AppRoutes.ambulanceNavigation,
              );
              break;
            case 3:
              break; // Current
          }
        },
        items: const [
          BottomNavItem(icon: Icons.grid_view_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.emergency_share_rounded, label: 'Requests'),
          BottomNavItem(icon: Icons.explore_rounded, label: 'Maps'),
          BottomNavItem(icon: Icons.manage_accounts_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  // Helper widget for Stat Cards
  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Helper widget for Profile Options
  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
