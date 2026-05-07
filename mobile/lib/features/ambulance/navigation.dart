import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class AmbulanceNavigationScreen extends StatelessWidget {
  const AmbulanceNavigationScreen({super.key});

  // Navigation is index 2 in our footer
  final int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Live Navigation',
        showBackButton: false,
      ),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          final assignment = provider.currentAssignment;

          if (assignment == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No Active Mission',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const Text('Accept a request to start navigation.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // --- MAP AREA ---
              Container(
                width: double.infinity,
                height: double.infinity,
                color: isDark ? Colors.blueGrey[900] : Colors.blueGrey[50],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.my_location,
                          size: 40, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Google Maps View Placeholder',
                        style: TextStyle(
                            color: Colors.blueGrey[400],
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Tracking: ${provider.currentLatitude.toStringAsFixed(4)}, ${provider.currentLongitude.toStringAsFixed(4)}',
                        style: TextStyle(
                            color: Colors.blueGrey[300], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // --- FLOATING DIRECTION CARD (Top) ---
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2), blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.turn_right_rounded,
                          color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Next Turn in 200m',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(assignment.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BOTTOM TRIP DETAILS PANEL ---
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 20)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTripStat('Distance', '4.2 km',
                              Icons.straighten_rounded, Colors.orange),
                          _buildTripStat('ETA', '${assignment.etaMinutes} min',
                              Icons.timer_rounded, Colors.blue),
                          _buildTripStat(
                              'Priority',
                              assignment.priority.toUpperCase(),
                              Icons.warning_amber_rounded,
                              Colors.red),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone),
                              label: const Text('Contact'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Logic to complete trip
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Trip Completed!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Arrived',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              if (hasActiveMission) {
                Navigator.pushReplacementNamed(
                    context, AppRoutes.ambulanceCurrentCase);
              }
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

  // Helper for bottom panel stats
  Widget _buildTripStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
