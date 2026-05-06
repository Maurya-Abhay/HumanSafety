import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';

class AmbulanceNavigationScreen extends StatelessWidget {
  const AmbulanceNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Navigation'),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          final assignment = provider.currentAssignment;
          if (assignment == null) {
            return Center(
              child: Text(
                'No active assignment',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destination: ${assignment.address}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📍 Lat: ${assignment.latitude.toStringAsFixed(4)}'),
                        Text('📍 Lon: ${assignment.longitude.toStringAsFixed(4)}'),
                        const SizedBox(height: 12),
                        Text('Current: ${provider.currentLatitude.toStringAsFixed(4)}, ${provider.currentLongitude.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.map, size: 80, color: Colors.blue),
                      const SizedBox(height: 12),
                      Text(
                        'Map integration with google_maps_flutter',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text('ETA: ${assignment.etaMinutes} minutes', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
