import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';

class AmbulanceSettingsScreen extends StatefulWidget {
  const AmbulanceSettingsScreen({super.key});

  @override
  State<AmbulanceSettingsScreen> createState() => _AmbulanceSettingsScreenState();
}

class _AmbulanceSettingsScreenState extends State<AmbulanceSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationSharingEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Ambulance Settings'),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Availability
              Card(
                child: SwitchListTile(
                  title: const Text('Available'),
                  subtitle: const Text('Toggle availability status'),
                  value: provider.isOnline,
                  onChanged: (value) async {
                    await provider.toggleOnlineStatus(value);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Vehicle Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle Information', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.local_hospital),
                        title: const Text('Ambulance ID'),
                        subtitle: const Text('AID-2026-001'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.speed),
                        title: const Text('Average Speed'),
                        subtitle: const Text('40 km/h'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: const Text('License Plate'),
                        subtitle: const Text('DL-01-AB-9999'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notifications
              Card(
                child: SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive emergency alerts'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Location Sharing
              Card(
                child: SwitchListTile(
                  title: const Text('Location Sharing'),
                  subtitle: const Text('Share real-time location'),
                  value: _locationSharingEnabled,
                  onChanged: (value) {
                    setState(() => _locationSharingEnabled = value);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Danger Zone
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danger Zone',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
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
