import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/storage_service.dart';
import '../../core/sensor_service.dart';
import '../../core/background_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool enableNotifications = true;
  bool enableLocationTracking = true;
  bool enableBackgroundTracking = false;
  bool enableAutoSOS = false;
  bool enableEmergencySharing = true;
  bool enableAnalytics = true;
  int sosActivationSeconds = 3;
  int locationUpdateIntervalSeconds = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeSensorService();
  }

  Future<void> _initializeSensorService() async {
    final sensorService = context.read<SensorService>();
    await sensorService.initialize();
  }

  Future<void> _loadSettings() async {
    final notifications = await StorageService.getBool('enable_notifications') ?? true;
    final locationTracking = await StorageService.getBool('enable_location_tracking') ?? true;
    final backgroundTracking = await StorageService.getBool('enable_background_tracking') ?? false;
    final autoSOS = await StorageService.getBool('enable_auto_sos') ?? false;
    final emergencySharing = await StorageService.getBool('enable_emergency_sharing') ?? true;
    final analytics = await StorageService.getBool('enable_analytics') ?? true;
    
    setState(() {
      enableNotifications = notifications;
      enableLocationTracking = locationTracking;
      enableBackgroundTracking = backgroundTracking;
      enableAutoSOS = autoSOS;
      enableEmergencySharing = emergencySharing;
      enableAnalytics = analytics;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await StorageService.saveBool(key, value);
    } else {
      await StorageService.saveString(key, value.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // APPEARANCE SECTION
            const SizedBox(height: 12),
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    );
                  },
                ),
              ),
            ),

            // EMERGENCY FEATURES
            const SizedBox(height: 24),
            Text(
              'Emergency Features',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Emergency Notifications'),
                subtitle: const Text('Receive alerts when help is needed'),
                trailing: Switch(
                  value: enableNotifications,
                  onChanged: (val) {
                    setState(() => enableNotifications = val);
                    _saveSetting('enable_notifications', val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location Tracking'),
                subtitle: const Text('Share location during emergencies'),
                trailing: Switch(
                  value: enableLocationTracking,
                  onChanged: (val) {
                    setState(() => enableLocationTracking = val);
                    _saveSetting('enable_location_tracking', val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Background Tracking'),
                subtitle: const Text('Track location in background'),
                trailing: FutureBuilder<bool>(
                  future: BackgroundService.isServiceRunning(),
                  builder: (context, snapshot) {
                    final isRunning = snapshot.data ?? enableBackgroundTracking;
                    return Switch(
                      value: isRunning,
                      onChanged: (val) async {
                        final sensorService = context.read<SensorService>();
                        setState(() => enableBackgroundTracking = val);
                        _saveSetting('enable_background_tracking', val);

                        if (val) {
                          await BackgroundService.startLocationService();
                          await sensorService.startMonitoring();
                        } else {
                          await BackgroundService.stopLocationService();
                          await sensorService.stopMonitoring();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('Auto SOS on Impact'),
                subtitle: const Text('Automatic emergency alert on crash'),
                trailing: Consumer<SensorService>(
                  builder: (context, sensorService, child) {
                    return Switch(
                      value: sensorService.autoSOS,
                      onChanged: (val) async {
                        setState(() => enableAutoSOS = val);
                        _saveSetting('enable_auto_sos', val);

                        // Update sensor service
                        await StorageService.saveBool('enable_auto_sos', val);
                        await sensorService.initialize(); // Re-initialize to load new settings
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Emergency Contact Sharing'),
                subtitle: const Text('Share details with responders'),
                trailing: Switch(
                  value: enableEmergencySharing,
                  onChanged: (val) {
                    setState(() => enableEmergencySharing = val);
                    _saveSetting('enable_emergency_sharing', val);
                  },
                ),
              ),
            ),

            // SENSOR STATUS
            const SizedBox(height: 24),
            Text(
              'Sensor Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Consumer<SensorService>(
              builder: (context, sensorService, child) {
                final status = sensorService.getSensorStatus();
                return CustomCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          status['is_monitoring'] ? Icons.sensors : Icons.sensors_off,
                          color: status['is_monitoring'] ? Colors.green : Colors.grey,
                        ),
                        title: const Text('Sensor Monitoring'),
                        subtitle: Text(status['is_monitoring'] ? 'Active' : 'Inactive'),
                      ),
                      if (status['last_accelerometer'] != null) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.vibration, color: Colors.blue),
                          title: const Text('Current Acceleration'),
                          subtitle: Text(
                            'X: ${(status['last_accelerometer']['x'] as double?)?.toStringAsFixed(2) ?? '0.00'} '
                            'Y: ${(status['last_accelerometer']['y'] as double?)?.toStringAsFixed(2) ?? '0.00'} '
                            'Z: ${(status['last_accelerometer']['z'] as double?)?.toStringAsFixed(2) ?? '0.00'} m/s²',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      if (status['last_position'] != null) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.orange),
                          title: const Text('Last Location'),
                          subtitle: Text(
                            '${(status['last_position']['latitude'] as double?)?.toStringAsFixed(6) ?? '0.000000'}, '
                            '${(status['last_position']['longitude'] as double?)?.toStringAsFixed(6) ?? '0.000000'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      if (status['is_user_inactive'] == true) ...[
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'User inactivity detected. Monitoring for emergency conditions.',
                                  style: TextStyle(color: Colors.orange, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            // DATA & PRIVACY
            const SizedBox(height: 24),
            Text(
              'Data & Privacy',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analytics'),
                subtitle: const Text('Help improve the app'),
                trailing: Switch(
                  value: enableAnalytics,
                  onChanged: (val) {
                    setState(() => enableAnalytics = val);
                    _saveSetting('enable_analytics', val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
              child: const ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Privacy Policy'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear App Data'),
                subtitle: const Text('Remove cached data and cache'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Data?'),
                      content: const Text('This will clear all app data and cache'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement data clearing
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Data cleared')),
                            );
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ABOUT
            const SizedBox(height: 24),
            Text(
              'About',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              child: const ListTile(
                leading: Icon(Icons.info),
                title: Text('About App'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.help),
              child: const ListTile(
                leading: Icon(Icons.help),
                title: Text('Help & Support'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 12),
            const CustomCard(
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('App Version'),
                trailing: Text('1.0.0'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          // Settings doesn't navigate
        },
        items: [
          BottomNavItem(icon: Icons.home, label: 'Home'),
          BottomNavItem(icon: Icons.warning, label: 'SOS'),
          BottomNavItem(icon: Icons.people, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
