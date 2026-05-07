import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/storage_service.dart';
import '../../core/routes.dart';

class AmbulanceSettingsScreen extends StatefulWidget {
  const AmbulanceSettingsScreen({super.key});

  @override
  State<AmbulanceSettingsScreen> createState() =>
      _AmbulanceSettingsScreenState();
}

class _AmbulanceSettingsScreenState extends State<AmbulanceSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationSharingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notifications =
        await StorageService.getBool('ambulance_notifications');
    final locationSharing =
        await StorageService.getBool('ambulance_location_sharing');

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notifications ?? true;
      _locationSharingEnabled = locationSharing ?? true;
    });
  }

  Future<void> _setNotifications(bool value) async {
    await StorageService.saveBool('ambulance_notifications', value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _setLocationSharing(bool value) async {
    await StorageService.saveBool('ambulance_location_sharing', value);
    if (!mounted) return;
    setState(() => _locationSharingEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Ambulance Settings'),
      body: Consumer3<AmbulanceProvider, ThemeProvider, AuthProvider>(
        builder: (context, ambulanceProvider, themeProvider, authProvider, _) {
          final user = authProvider.user;
          final locationLabel =
              '${ambulanceProvider.currentLatitude.toStringAsFixed(4)}, ${ambulanceProvider.currentLongitude.toStringAsFixed(4)}';

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('Available'),
                  subtitle: const Text('Toggle availability status'),
                  value: ambulanceProvider.isOnline,
                  onChanged: (value) async {
                    await ambulanceProvider.toggleOnlineStatus(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Turn dark theme on/off'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    await themeProvider.setTheme(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive emergency alerts'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    _setNotifications(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Location Sharing'),
                  subtitle: const Text('Share real-time location'),
                  value: _locationSharingEnabled,
                  onChanged: (value) {
                    _setLocationSharing(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Driver Information',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Driver Name'),
                        subtitle: Text(user?.name.isNotEmpty == true
                            ? user!.name
                            : 'Not available'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Phone Number'),
                        subtitle: Text(user?.phone.isNotEmpty == true
                            ? user!.phone
                            : 'Not available'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(user?.email.isNotEmpty == true
                            ? user!.email
                            : 'Not available'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.assignment_ind_outlined),
                        title: const Text('Account Role'),
                        subtitle:
                            Text((user?.role ?? 'ambulance').toUpperCase()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Stats',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ListTile(
                        leading:
                            const Icon(Icons.directions_car_filled_outlined),
                        title: const Text('Total Trips'),
                        subtitle: Text('${ambulanceProvider.totalTrips}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.star_outline),
                        title: const Text('Average Rating'),
                        subtitle: Text(
                            ambulanceProvider.averageRating.toStringAsFixed(1)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.my_location_outlined),
                        title: const Text('Current Location'),
                        subtitle: Text(locationLabel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.local_hospital_outlined),
                        title: const Text('Current Assignment'),
                        subtitle: Text(
                          ambulanceProvider.currentAssignment != null
                              ? ambulanceProvider.currentAssignment!.patientName
                              : 'No active case',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danger Zone',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await authProvider.logout();
                            if (!mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Emergency Logout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
