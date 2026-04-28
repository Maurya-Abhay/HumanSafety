import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/sensor_service.dart';
import '../../core/background_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _sosActive = false;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  CaseResponse? _caseResponse;
  bool _sensorMonitoring = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _initializeSensorService();
  }

  @override
  void dispose() {
    _stopSensorMonitoring();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _initializeSensorService() async {
    final sensorService = context.read<SensorService>();
    await sensorService.initialize();

    // Set up callbacks
    sensorService.onImpactDetected = _onImpactDetected;
    sensorService.onAccidentDetected = _onAccidentDetected;
    sensorService.onLocationUpdate = _onLocationUpdate;
  }

  void _onImpactDetected(double magnitude) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impact detected: ${magnitude.toStringAsFixed(1)} m/s²'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _onAccidentDetected() {
    if (mounted && !_sosActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accident detected! Auto-SOS activated'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
      _triggerAutoSOS();
    }
  }

  void _onLocationUpdate(Position position) {
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    });
  }

  Future<void> _triggerAutoSOS() async {
    try {
      setState(() => _isLoading = true);
      final sensorService = context.read<SensorService>();

      if (_latitude == null || _longitude == null) {
        await _getCurrentLocation();
      }

      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) return;
      final status = sensorService.getSensorStatus();

      final response = await ApiService.createPanicAlert(
        token,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        description: 'Auto-detected accident via sensors',
        sensorData: {
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'sos_auto',
          'sensor_status': status,
        },
      );

      if (!mounted) return;

      setState(() {
        _caseResponse = response;
        _sosActive = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Auto-SOS error: $e');
    }
  }

  Future<void> _startSensorMonitoring() async {
    final sensorService = context.read<SensorService>();
    await sensorService.startMonitoring();
    setState(() => _sensorMonitoring = true);
  }

  Future<void> _stopSensorMonitoring() async {
    final sensorService = context.read<SensorService>();
    await sensorService.stopMonitoring();
    setState(() => _sensorMonitoring = false);
  }

  Future<void> _toggleBackgroundTracking() async {
    final sensorService = context.read<SensorService>();
    final isRunning = await BackgroundService.isServiceRunning();

    if (isRunning) {
      await BackgroundService.stopLocationService();
      await sensorService.stopMonitoring();
    } else {
      await BackgroundService.startLocationService();
      await sensorService.startMonitoring();
    }

    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationAddress = '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: ${e.toString()}')),
      );
    }
  }

  Future<void> _triggerSOS() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current location
      await _getCurrentLocation();
      if (!mounted) return;
      
      if (_latitude == null || _longitude == null) {
        throw Exception('Unable to get location');
      }

      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create panic alert with location
      final response = await ApiService.createPanicAlert(
        token,
        latitude: _latitude!,
        longitude: _longitude!,
        description: 'Emergency SOS triggered',
        sensorData: {
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'sos_manual',
        },
      );

      if (!mounted) return;

      setState(() {
        _caseResponse = response;
        _sosActive = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS activated! Help is on the way')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _cancelSOS() {
    setState(() {
      _sosActive = false;
      _caseResponse = null;
      _latitude = null;
      _longitude = null;
      _locationAddress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Emergency SOS'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  if (_sosActive)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'SOS Activated',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Help is on the way'),
                        if (_locationAddress != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Location: $_locationAddress',
                            style: const TextStyle(fontSize: 12, color: AppColors.grey),
                          ),
                        ],
                        if (_caseResponse != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Case ID: ${_caseResponse!.caseId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Risk Level: ${_caseResponse!.riskLevel}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  if (!_sosActive)
                    const Column(
                      children: [
                        Text(
                          'Emergency SOS',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text('Tap the SOS button for immediate help'),
                        SizedBox(height: 50),
                      ],
                    ),
                  SOSButton(
                    isActive: _sosActive,
                    onPressed: _isLoading
                        ? () {}
                        : () {
                            if (_sosActive) {
                              _cancelSOS();
                            } else {
                              _triggerSOS();
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            // Sensor Monitoring Section
            CustomCard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _sensorMonitoring ? Icons.sensors : Icons.sensors_off,
                      color: _sensorMonitoring ? AppColors.success : AppColors.grey,
                    ),
                    title: const Text('Sensor Monitoring'),
                    subtitle: Text(_sensorMonitoring ? 'Active - Detecting accidents' : 'Inactive'),
                    trailing: Switch(
                      value: _sensorMonitoring,
                      onChanged: (value) {
                        if (value) {
                          _startSensorMonitoring();
                        } else {
                          _stopSensorMonitoring();
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  Consumer<SensorService>(
                    builder: (context, sensorService, child) {
                      final status = sensorService.getSensorStatus();
                      return Column(
                        children: [
                          if (status['last_accelerometer'] != null)
                            ListTile(
                              leading: const Icon(Icons.vibration, color: AppColors.info),
                              title: const Text('Last Acceleration'),
                              subtitle: Text(
                                '${(status['last_accelerometer']['x'] as double?)?.toStringAsFixed(2) ?? '0.00'}, '
                                '${(status['last_accelerometer']['y'] as double?)?.toStringAsFixed(2) ?? '0.00'}, '
                                '${(status['last_accelerometer']['z'] as double?)?.toStringAsFixed(2) ?? '0.00'} m/s²',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          if (status['is_user_inactive'] == true)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.warning),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning, color: AppColors.warning),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Inactivity detected - monitoring for emergency',
                                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Background Tracking Section
            CustomCard(
              child: FutureBuilder<bool>(
                future: BackgroundService.isServiceRunning(),
                builder: (context, snapshot) {
                  final isRunning = snapshot.data ?? false;
                  return ListTile(
                    leading: Icon(
                      isRunning ? Icons.location_on : Icons.location_off,
                      color: isRunning ? AppColors.success : AppColors.grey,
                    ),
                    title: const Text('Background Location'),
                    subtitle: Text(isRunning ? 'Active - Continuous monitoring' : 'Inactive'),
                    trailing: Switch(
                      value: isRunning,
                      onChanged: (value) => _toggleBackgroundTracking(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            if (_sosActive) ...[
              const Divider(),
              const SizedBox(height: 20),
              Text(
                'Emergency Contacts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CustomCard(
                child: ListTile(
                  leading: const Icon(Icons.call, color: AppColors.accent),
                  title: const Text('Police'),
                  subtitle: const Text('Emergency services'),
                  trailing: const Icon(Icons.call_made),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                child: ListTile(
                  leading: const Icon(Icons.call, color: AppColors.info),
                  title: const Text('Ambulance'),
                  subtitle: const Text('Medical emergency'),
                  trailing: const Icon(Icons.call_made),
                  onTap: () {},
                ),
              ),
            ]
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          // SOS doesn't navigate
        },
        items: [
          BottomNavItem(icon: Icons.home, label: 'Home'),
          BottomNavItem(icon: Icons.warning, label: 'SOS'),
          BottomNavItem(icon: Icons.people, label: 'Contacts'),
          BottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}
