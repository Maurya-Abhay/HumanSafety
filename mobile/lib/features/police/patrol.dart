import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class PatrolScreen extends StatefulWidget {
  const PatrolScreen({super.key});

  @override
  State<PatrolScreen> createState() => _PatrolScreenState();
}

class _PatrolScreenState extends State<PatrolScreen> {
  Position? _currentPosition;
  bool _isPatrolActive = false;
  bool _isLoading = false;
  DateTime? _patrolStartTime;
  int _patientsHelped = 0;
  int _incidentsReported = 0;
  double _distanceTraveled = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPatrolStatus();
  }

  Future<void> _loadPatrolStatus() async {
    final status = await StorageService.getBool('patrolActive') ?? false;
    final patientsStr = await StorageService.getString('patientsHelped') ?? '0';
    final incidentsStr = await StorageService.getString('incidentsReported') ?? '0';
    final distanceStr = await StorageService.getString('distanceTraveled') ?? '0.0';

    if (mounted) {
      setState(() {
        _isPatrolActive = status;
        _patientsHelped = int.tryParse(patientsStr) ?? 0;
        _incidentsReported = int.tryParse(incidentsStr) ?? 0;
        _distanceTraveled = double.tryParse(distanceStr) ?? 0.0;
      });
    }
    if (_isPatrolActive) _startLocationUpdates();
  }

  Future<void> _togglePatrol() async {
    setState(() => _isLoading = true);
    try {
      if (!_isPatrolActive) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          await Geolocator.requestPermission();
        }
        _patrolStartTime = DateTime.now();
        _startLocationUpdates();
      } else {
        _patrolStartTime = null;
      }

      setState(() => _isPatrolActive = !_isPatrolActive);
      await StorageService.saveBool('patrolActive', _isPatrolActive);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPatrolActive ? 'Patrol started' : 'Patrol ended'),
            backgroundColor: _isPatrolActive ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startLocationUpdates() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  void _addPatientHelped() {
    setState(() => _patientsHelped++);
    StorageService.saveString('patientsHelped', _patientsHelped.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Patients helped: $_patientsHelped')),
    );
  }

  void _reportIncident() {
    setState(() => _incidentsReported++);
    StorageService.saveString('incidentsReported', _incidentsReported.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Incidents reported: $_incidentsReported')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Patrol Duty',
        showBackButton: false,
        actions: [
          _buildActionCircle(Icons.notifications_none_rounded, AppRoutes.policeNotifications),
          _buildActionCircle(Icons.person_outline_rounded, AppRoutes.policeProfile),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patrol Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPatrolActive
                      ? [Colors.green.shade600, Colors.green.shade400]
                      : [Colors.grey.shade600, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (_isPatrolActive ? Colors.green : Colors.grey).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                            _isPatrolActive ? 'PATROL ACTIVE' : 'PATROL INACTIVE',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _patrolStartTime != null
                                ? 'Since ${_patrolStartTime!.toString().split('.')[0]}'
                                : 'No active patrol',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Icon(
                          _isPatrolActive ? Icons.directions_car_filled : Icons.directions_car_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _togglePatrol,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _isPatrolActive ? Colors.green : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isLoading
                            ? 'Processing...'
                            : _isPatrolActive
                                ? 'END PATROL'
                                : 'START PATROL',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location Info
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Patrol Statistics
            Text(
              'Patrol Statistics',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Patients Helped', _patientsHelped.toString(), Icons.people_rounded, Colors.blue),
                _buildStatCard('Incidents Reported', _incidentsReported.toString(), Icons.warning_rounded, Colors.orange),
                _buildStatCard('Distance', '${_distanceTraveled.toStringAsFixed(1)} km', Icons.route_rounded, Colors.purple),
                _buildStatCard('Duty Time', _getDutyTime(), Icons.schedule_rounded, Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Patient Helped',
                    Icons.add_circle_outline_rounded,
                    Colors.blue,
                    _addPatientHelped,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Report Incident',
                    Icons.warning_outlined,
                    Colors.orange,
                    _reportIncident,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Checklist
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Duty Checklist', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  _buildChecklistItem('Vehicle Inspected', true),
                  _buildChecklistItem('Equipment Check', true),
                  _buildChecklistItem('Backup Available', true),
                  _buildChecklistItem('Communication Test', false),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.policeDashboard);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.policeCases);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.policeSettings);
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.directions_car_rounded, label: 'Patrol'),
          BottomNavItem(icon: Icons.assignment_rounded, label: 'Cases'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(isChecked ? Icons.check_circle : Icons.circle_outlined, color: isChecked ? Colors.green : AppColors.grey, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isChecked ? Colors.green : AppColors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String route) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  String _getDutyTime() {
    if (_patrolStartTime == null) return '--:--';
    final duration = DateTime.now().difference(_patrolStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
