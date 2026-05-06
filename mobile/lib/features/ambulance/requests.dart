import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';

class AmbulanceRequestsScreen extends StatefulWidget {
  const AmbulanceRequestsScreen({super.key});

  @override
  State<AmbulanceRequestsScreen> createState() => _AmbulanceRequestsScreenState();
}

class _AmbulanceRequestsScreenState extends State<AmbulanceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AmbulanceProvider>().loadRequests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Incoming Requests'),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No incoming requests',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.assignments.length,
            itemBuilder: (_, idx) {
              final assignment = provider.assignments[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            assignment.patientName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Chip(
                            label: Text(
                              assignment.priority.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: assignment.priority == 'critical'
                                ? Colors.red
                                : assignment.priority == 'high'
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(assignment.address)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('ETA: ${assignment.etaMinutes} minutes'),
                        ],
                      ),
                      if (assignment.description != null) ...[        const SizedBox(height: 4),
                        Text('Notes: ${assignment.description}'),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await provider.acceptRequest(assignment.id, assignment.etaMinutes);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Assignment accepted!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
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
