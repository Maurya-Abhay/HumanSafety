import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyHospitals = [];
  List<Map<String, dynamic>> _nearbyPolice = [];
  List<Map<String, dynamic>> _nearbyAmbulances = [];
  bool _isLoading = true;
  String? _error;
  late StreamSubscription<Position> _positionStream;
  Timer? _updateTimer;
  Map<String, dynamic>? _caseData;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      // Get current position
      await _getCurrentLocation();
      
      // Fetch nearby responders
      await _fetchNearbyResponders();
      
      // Start live position updates every 5 seconds
      _startLiveUpdates();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() => _currentPosition = position);
      
      // Save location to server
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null) {
        await ApiService.updateLocation(
          token,
          position.latitude,
          position.longitude,
          position.accuracy,
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
      rethrow;
    }
  }

  Future<void> _fetchNearbyResponders() async {
    if (_currentPosition == null) return;

    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) return;

      // Simulate fetching nearby hospitals, police, and ambulances
      // In real scenario, these would be actual API calls
      final hospitals = await _getNearbyHospitals(token);
      final police = await _getNearbyPolice(token);
      final ambulances = await _getNearbyAmbulances(token);

      setState(() {
        _nearbyHospitals = hospitals;
        _nearbyPolice = police;
        _nearbyAmbulances = ambulances;
      });
    } catch (e) {
      debugPrint('Fetch responders error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getNearbyHospitals(String token) async {
    // Mock data - replace with actual API call
    // In production: await ApiService.getNearbyHospitals(token, lat, lng);
    if (_currentPosition == null) return [];
    
    return [
      {
        'id': '1',
        'name': 'City Medical Hospital',
        'distance': _calculateDistance(28.7041, 77.1025),
        'time': 12,
        'address': 'Sector 42, Delhi',
        'phone': '+91-9999-999999',
        'latitude': 28.7041,
        'longitude': 77.1025,
        'beds': 150,
      },
      {
        'id': '2',
        'name': 'Emergency Care Center',
        'distance': _calculateDistance(28.7100, 77.1150),
        'time': 18,
        'address': 'Green Park, Delhi',
        'phone': '+91-8888-888888',
        'latitude': 28.7100,
        'longitude': 77.1150,
        'beds': 85,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _getNearbyPolice(String token) async {
    if (_currentPosition == null) return [];
    
    return [
      {
        'id': 'P1',
        'name': 'Police Unit - P442',
        'distance': _calculateDistance(28.7045, 77.1028),
        'time': 5,
        'address': 'Police Station, Sector 40',
        'phone': '+91-100',
        'latitude': 28.7045,
        'longitude': 77.1028,
        'officers': 15,
      },
      {
        'id': 'P2',
        'name': 'Mobile Patrol Unit',
        'distance': _calculateDistance(28.7120, 77.1160),
        'time': 8,
        'address': 'Patrolling Area',
        'phone': '+91-100',
        'latitude': 28.7120,
        'longitude': 77.1160,
        'officers': 5,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _getNearbyAmbulances(String token) async {
    if (_currentPosition == null) return [];
    
    return [
      {
        'id': 'A1',
        'name': 'Ambulance - Medic 9',
        'distance': _calculateDistance(28.7055, 77.1038),
        'time': 8,
        'address': 'On Route',
        'phone': '+91-102',
        'latitude': 28.7055,
        'longitude': 77.1038,
        'status': 'Enroute',
      },
      {
        'id': 'A2',
        'name': 'Emergency Response - ER 7',
        'distance': _calculateDistance(28.7130, 77.1170),
        'time': 15,
        'address': 'Hospital Standby',
        'phone': '+91-102',
        'latitude': 28.7130,
        'longitude': 77.1170,
        'status': 'Dispatched',
      },
    ];
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0;
    
    const p = 0.017453292519943295;
    final a = 0.5 - cos((_currentPosition!.latitude - lat) * p) / 2 +
        cos(lat * p) * cos(_currentPosition!.latitude * p) *
            (1 - cos((_currentPosition!.longitude - lng) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km; returns in meters then km
  }

  void _startLiveUpdates() {
    // Update location every 5 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await _getCurrentLocation();
        await _fetchNearbyResponders();
      } catch (e) {
        debugPrint('Live update error: $e');
      }
    });
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Live Assistance Tracking'),
        body: const Center(child: LoadingWidget(message: 'Loading live tracking...')),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Live Assistance Tracking'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Retry',
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initializeTracking();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Live Assistance Tracking',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _fetchNearbyResponders(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Info Card
                if (_currentPosition != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Your Location',
                                  style: TextStyle(fontSize: 12, color: AppColors.grey)),
                              Text(
                                '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Live', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Status Timeline
                _buildLiveStatusCard(isDark),
                const SizedBox(height: 32),

                // Hospitals Section
                if (_nearbyHospitals.isNotEmpty) ...[
                  _buildSectionHeader('🏥 Nearby Hospitals'),
                  const SizedBox(height: 12),
                  ..._nearbyHospitals.map((h) => _buildResponderCard(h, Colors.red, isDark)),
                  const SizedBox(height: 24),
                ],

                // Ambulances Section
                if (_nearbyAmbulances.isNotEmpty) ...[
                  _buildSectionHeader('🚑 Emergency Ambulances'),
                  const SizedBox(height: 12),
                  ..._nearbyAmbulances.map((a) => _buildResponderCard(a, Colors.orange, isDark)),
                  const SizedBox(height: 24),
                ],

                // Police Section
                if (_nearbyPolice.isNotEmpty) ...[
                  _buildSectionHeader('👮 Nearby Police Units'),
                  const SizedBox(height: 12),
                  ..._nearbyPolice.map((p) => _buildResponderCard(p, Colors.blue, isDark)),
                  const SizedBox(height: 24),
                ],

                // Cancel Alert Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Alert?'),
                          content: const Text('Are you sure you are safe and want to cancel the emergency alert?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('No, Keep Alert'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: const Text('Yes, I\'m Safe'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      "CANCEL ALERT (I AM SAFE)",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResponderCard(Map<String, dynamic> data, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  data.containsKey('beds') ? Icons.local_hospital_rounded :
                  data.containsKey('status') ? Icons.emergency_rounded :
                  Icons.local_police_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Text(
                      data['address'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${data['time']} min',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(data['distance'] / 1000).toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['phone'] ?? 'N/A',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.call_rounded, size: 16),
                label: const Text('Call'),
                onPressed: () {
                  // Implement actual call functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${data['phone']}')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusStep(true, "Alert", isDark),
              _buildStatusConnector(true),
              _buildStatusStep(true, "Dispatched", isDark),
              _buildStatusConnector(true),
              _buildStatusStep(true, "Enroute", isDark),
              _buildStatusConnector(false),
              _buildStatusStep(false, "Arrived", isDark),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Rescue teams have been notified and are on the way to your location.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(bool completed, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed ? AppColors.primary : Colors.grey.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            completed ? Icons.check : Icons.circle,
            size: 16,
            color: completed ? Colors.white : Colors.grey.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: completed ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusConnector(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey.withOpacity(0.2),
        ),
      ),
    );
  }
}

