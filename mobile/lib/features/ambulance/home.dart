import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class AmbulanceHomeScreen extends StatefulWidget {
  const AmbulanceHomeScreen({super.key});

  @override
  State<AmbulanceHomeScreen> createState() => _AmbulanceHomeScreenState();
}

class _AmbulanceHomeScreenState extends State<AmbulanceHomeScreen> {
  final int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AmbulanceProvider>().loadRequests();
        context.read<AmbulanceProvider>().loadProfileStats();
      }
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444); // Modern Red
      case 'high':
        return const Color(0xFFF59E0B); // Modern Amber
      case 'medium':
        return const Color(0xFF3B82F6); // Modern Blue
      case 'low':
        return const Color(0xFF10B981); // Modern Green
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AmbulanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Ambulance Pro',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            onPressed: () => provider.loadRequests(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadRequests();
          await provider.loadProfileStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Premium Hero Header ---
              _buildHeroSection(provider),
              const SizedBox(height: 24),

              // --- Statistics Grid ---
              Text('Performance Overview',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard(
                      'Status',
                      provider.isOnline ? 'Online' : 'Offline',
                      provider.isOnline ? Colors.green : Colors.red,
                      Icons.sensors),
                  _buildStatCard('Total Trips', provider.totalTrips.toString(),
                      Colors.blue, Icons.map),
                  _buildStatCard(
                      'Rating',
                      provider.averageRating.toStringAsFixed(1),
                      Colors.amber,
                      Icons.star_rounded),
                  _buildStatCard(
                      'Pending',
                      provider.assignments.length.toString(),
                      Colors.purple,
                      Icons.pending_actions),
                ],
              ),
              const SizedBox(height: 24),

              // --- Active Assignment (Premium Look) ---
              if (provider.currentAssignment != null) ...[
                _buildSectionHeader('Live Mission'),
                _buildActiveAssignmentCard(provider),
                const SizedBox(height: 24),
              ],

              // --- Incoming Requests ---
              _buildSectionHeader('Incoming Requests'),
              const SizedBox(height: 12),
              _buildRequestList(provider, context),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(
                  context, AppRoutes.ambulanceRequests);
              break;
            case 2:
              Navigator.pushReplacementNamed(
                  context, AppRoutes.ambulanceNavigation);
              break;
            case 3:
              Navigator.pushReplacementNamed(
                  context, AppRoutes.ambulanceSettings);
              break;
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

  // Helper: Hero Header
  Widget _buildHeroSection(AmbulanceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: provider.isOnline
              ? [const Color(0xFF2563EB), const Color(0xFF3B82F6)]
              : [const Color(0xFF475569), const Color(0xFF64748B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (provider.isOnline ? Colors.blue : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Emergency Responder',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Text('Welcome Back! 🚑',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => provider.toggleOnlineStatus(!provider.isOnline),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: provider.isOnline ? Colors.red : Colors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              provider.isOnline ? 'Go Offline' : 'Go Online Now',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Stat Cards
  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Active Mission Card
  Widget _buildActiveAssignmentCard(AmbulanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white)),
            title: Text(provider.currentAssignment!.patientName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(provider.currentAssignment!.address,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${provider.currentAssignment!.etaMinutes}m',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(),
          ElevatedButton.icon(
            onPressed: () => provider.markArrived(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Arrival at Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildRequestList(AmbulanceProvider provider, BuildContext context) {
    if (provider.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (provider.assignments.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Icon(Icons.notifications_none_rounded,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('No pending requests',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.assignments.length,
      itemBuilder: (context, index) {
        final req = provider.assignments[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(req.patientName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(req.address, style: const TextStyle(fontSize: 13)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(req.priority).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    req.priority.toUpperCase(),
                    style: TextStyle(
                        color: _getPriorityColor(req.priority),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${req.etaMinutes} min',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            onTap: () async {
              await provider.acceptRequest(req.id, req.etaMinutes);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mission Accepted!')));
              }
            },
          ),
        );
      },
    );
  }
}
