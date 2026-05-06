import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';

class AmbulanceHistoryScreen extends StatefulWidget {
  const AmbulanceHistoryScreen({super.key});

  @override
  State<AmbulanceHistoryScreen> createState() => _AmbulanceHistoryScreenState();
}

class _AmbulanceHistoryScreenState extends State<AmbulanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AmbulanceProvider>().loadTripHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Trip History'),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.tripHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No completed trips yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.tripHistory.length,
            itemBuilder: (_, idx) {
              final trip = provider.tripHistory[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text('Trip #${idx + 1} - ${trip.patientName}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location: ${trip.address}'),
                      Text('Date: ${trip.createdAt.toString().split('.')[0]}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(trip.status),
                    backgroundColor: trip.status == 'completed' ? Colors.green : Colors.orange,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
