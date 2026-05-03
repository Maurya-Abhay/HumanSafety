import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/portal_sound_service.dart';
// Real-time tracking service
import '../../core/ambulance_tracking_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late String _token;
  List<CaseItem> _requests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() => _isLoading = true);
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      if (_token.isNotEmpty) {
        final requests = await ApiService.getHospitalAlerts(_token);
        setState(() {
          _requests = requests;
          _error = null;
        });
        if (requests.isNotEmpty) {
          await PortalSoundService().playAlert();
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(String caseId) async {
    try {
      await ApiService.acceptEmergency(_token, caseId);
      await PortalSoundService().playNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency accepted')),
      );
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Request Center',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEE2E2), Color(0xFFFFF7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital_rounded, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Emergency Requests', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${_requests.length} requests waiting for review', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Center(child: Text('Error: $_error'))
            else if (_requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No pending requests')),
              )
            else
              ..._requests.map((request) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.emergency_share_rounded, color: AppColors.accent),
                      ),
                      title: Text(request.description ?? 'Emergency Request', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Location: ${request.location}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(request.createdAt.toString().split('.')[0], style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                          ],
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _acceptRequest(request.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Requests tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalDashboard);
          }
          if (index == 1) return; // Current page
          if (index == 2) {
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalAmbulance);
          }
          if (index == 3) {
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalSettings);
          }
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  late String _token;
  List<AmbulanceInfo> _ambulances = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAmbulances();
  }

  @override
  void dispose() {
    AmbulanceTrackingService().disconnect();
    super.dispose();
  }

  Future<void> _loadAmbulances() async {
    try {
      setState(() => _isLoading = true);
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      if (_token.isNotEmpty) {
        final ambulances = await ApiService.getHospitalAmbulances(_token);
        setState(() {
          _ambulances = ambulances;
          _error = null;
        });
        // Connect to real-time ambulance tracking
        _connectTracking();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectTracking() async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      final userJson = await StorageService.getJson(AppConstants.userKey);
      final userId = userJson?['_id'] ?? userJson?['id'] ?? '';
      if (token.isEmpty || userId.isEmpty) return;

      final connected = await AmbulanceTrackingService().connect(AppConstants.wsUrl, userId, token);
      if (!connected) return;

      AmbulanceTrackingService().locations.listen((update) {
        final idx = _ambulances.indexWhere((a) => a.id == update.ambulanceId);
        if (idx >= 0) {
          final existing = _ambulances[idx];
          final updated = AmbulanceInfo(
            id: existing.id,
            licenseNumber: existing.licenseNumber,
            driverName: existing.driverName,
            status: update.status,
            location: {
              'latitude': update.latitude,
              'longitude': update.longitude,
              'accuracy': update.accuracy,
              'updatedAt': update.timestamp.toIso8601String(),
            },
            eta: {'estimatedMinutes': update.eta},
            assignedPatient: existing.assignedPatient,
            isOnline: true,
          );

          if (!mounted) return;
          setState(() {
            _ambulances[idx] = updated;
          });
        } else {
          // If ambulance not in list, add a minimal entry
          final added = AmbulanceInfo(
            id: update.ambulanceId,
            licenseNumber: update.ambulanceId,
            driverName: 'Driver',
            status: update.status,
            location: {
              'latitude': update.latitude,
              'longitude': update.longitude,
              'accuracy': update.accuracy,
              'updatedAt': update.timestamp.toIso8601String(),
            },
            eta: {'estimatedMinutes': update.eta},
            assignedPatient: null,
            isOnline: true,
          );
          if (!mounted) return;
          setState(() => _ambulances.insert(0, added));
        }
      });
    } catch (e) {
      // ignore connection errors for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ambulance Fleet',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAmbulances,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _ambulances.isEmpty
                    ? const Center(child: Text('No ambulances available'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8F5E9), Color(0xFFF8FBFF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_hospital_rounded, color: AppColors.success),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Real-Time Fleet Tracking', style: TextStyle(fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Text('${_ambulances.length} ambulances in service', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._ambulances.map((ambulance) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildAmbulanceCard(ambulance),
                              )),
                        ],
                      ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalDashboard);
          }
          if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalRequests);
          }
          if (index == 2) return;
          if (index == 3) {
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalSettings);
          }
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildAmbulanceCard(AmbulanceInfo ambulance) {
    final statusColor = _getStatusColor(ambulance.status);
    final eta = ambulance.eta?['estimatedMinutes'] as int? ?? 0;
    final location = ambulance.location;
    final latitude = location?['latitude'] as double? ?? 0.0;
    final longitude = location?['longitude'] as double? ?? 0.0;

    return CustomCard(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_hospital_rounded, color: statusColor),
            ),
            title: Text(ambulance.licenseNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(ambulance.driverName, style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                ambulance.status.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GPS Location', style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('$latitude, $longitude',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (ambulance.isOnline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 6,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text('Online', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 6,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text('Offline', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ETA', style: TextStyle(fontSize: 10, color: AppColors.grey)),
                              Text('$eta min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _launchCall(ambulance.driverName),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Driver', style: TextStyle(fontSize: 10, color: AppColors.grey)),
                                  Text(ambulance.driverName,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'on-duty':
        return Colors.blue;
      case 'in-transit':
        return Colors.orange;
      case 'at-location':
        return Colors.red;
      case 'unavailable':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _launchCall(String driverName) async {
    final uri = Uri.parse('tel:');
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }
}

class HospitalCasesScreen extends StatefulWidget {
  const HospitalCasesScreen({super.key});

  @override
  State<HospitalCasesScreen> createState() => _HospitalCasesScreenState();
}

class _HospitalCasesScreenState extends State<HospitalCasesScreen> {
  bool _loading = true;
  String? _error;
  List<CaseItem> _cases = [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null || token.isEmpty) {
        setState(() => _cases = []);
        return;
      }
      final cases = await ApiService.getHospitalAlerts(token);
      if (!mounted) return;
      setState(() => _cases = cases);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hospital Cases',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._cases.map((caseItem) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.medical_services_rounded, color: AppColors.info),
                                ),
                                title: Text(caseItem.caseId.isNotEmpty ? 'Case ${caseItem.caseId}' : caseItem.id, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Status: ${caseItem.status}', style: const TextStyle(fontSize: 12)),
                                    Text('Risk: ${caseItem.riskLevel} (${caseItem.riskScore})', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                onTap: () => _showCaseDetails(caseItem),
                              ),
                            ),
                          )),
                      if (_cases.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('No cases found')),
                        ),
                    ],
                  ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Cases are grouped under Requests
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalDashboard);
          }
          if (index == 1) return; // Current page
          if (index == 2) {
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalAmbulance);
          }
          if (index == 3) {
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalSettings);
          }
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }

  void _showCaseDetails(CaseItem caseItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(caseItem.caseId.isNotEmpty ? 'Case ${caseItem.caseId}' : 'Case Details', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(caseItem.description ?? 'No description available', style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 12),
            Text('Status: ${caseItem.status}'),
            Text('Type: ${caseItem.type}'),
            Text('Risk score: ${caseItem.riskScore}'),
            const SizedBox(height: 16),
            const Text('Update Status:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusButton('In Progress', 'in-progress', caseItem),
                _buildStatusButton('Resolved', 'resolved', caseItem),
                _buildStatusButton('Transferred', 'transferred', caseItem),
                _buildStatusButton('Discharged', 'discharged', caseItem),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: 'Close', onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, CaseItem caseItem) {
    return ElevatedButton(
      onPressed: () => _updateCaseStatus(caseItem.id, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  Future<void> _updateCaseStatus(String caseId, String newStatus) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      await ApiService.updateAlertStatus(token, caseId, newStatus);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
      _loadCases(); // Reload to reflect changes
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Hospital Profile'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(Icons.local_hospital_rounded, color: Colors.white, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'Hospital profile is managed in the main profile screen',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Open the full profile to edit live hospital details, name, phone, and capacity.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Open Live Profile',
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.hospitalProfile),
            ),
          ],
        ),
      ),
    );
  }
}
