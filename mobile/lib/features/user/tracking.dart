import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Live Tracking'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Map placeholder
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 48, color: AppColors.grey),
                    SizedBox(height: 12),
                    Text('Map View'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nearby Responders',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                  child: const Icon(Icons.local_police, color: Colors.white),
                ),
                title: const Text('Police Unit'),
                subtitle: const Text('2.5 km away - 5 mins'),
                trailing: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.info),
                  child: const Icon(Icons.local_hospital, color: Colors.white),
                ),
                title: const Text('Ambulance'),
                subtitle: const Text('3.2 km away - 7 mins'),
                trailing: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tracking Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Location', '45.34° N, 75.42° W'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Status', 'Active'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Started', '2 minutes ago'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
