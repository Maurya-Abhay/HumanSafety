import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class AmbulanceRequestsScreen extends StatefulWidget {
  const AmbulanceRequestsScreen({super.key});

  @override
  State<AmbulanceRequestsScreen> createState() =>
      _AmbulanceRequestsScreenState();
}

class _AmbulanceRequestsScreenState extends State<AmbulanceRequestsScreen> {
  // Current index 1 stands for 'Requests' tab
  final int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AmbulanceProvider>().loadRequests();
      }
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Emergency Requests',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => context.read<AmbulanceProvider>().loadRequests(),
          )
        ],
      ),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (provider.assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No Incoming Requests',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const Text('We\'ll notify you when a call arrives.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: provider.assignments.length,
            itemBuilder: (_, idx) {
              final assignment = provider.assignments[idx];
              final pColor = _getPriorityColor(assignment.priority);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: pColor.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Top Priority Badge Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.flash_on_rounded,
                                  size: 14, color: pColor),
                              const SizedBox(width: 4),
                              Text(
                                assignment.priority.toUpperCase(),
                                style: TextStyle(
                                    color: pColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                          Text('${assignment.etaMinutes} mins away',
                              style: TextStyle(
                                  color: pColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assignment.patientName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(assignment.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600])),
                              ),
                            ],
                          ),
                          if (assignment.description != null &&
                              assignment.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Note: ${assignment.description}',
                                style: const TextStyle(
                                    fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                final success = await provider.acceptRequest(
                                    assignment.id, assignment.etaMinutes);
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Mission Accepted! Opening navigation...')),
                                  );
                                  // Open dedicated current case page after accepting request
                                  Navigator.pushReplacementNamed(
                                      context, AppRoutes.ambulanceCurrentCase);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Accept Call Now',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      // FOOTER ADDED HERE
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.ambulanceHome);
              break;
            case 1:
              break; // Already here
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
              Navigator.pushReplacementNamed(
                  context, AppRoutes.ambulanceProfile);
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
}
