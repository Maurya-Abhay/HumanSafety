import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/page_transitions.dart';
import './requests.dart';

class AmbulanceHomeScreen extends StatefulWidget {
  const AmbulanceHomeScreen({super.key});

  @override
  State<AmbulanceHomeScreen> createState() => _AmbulanceHomeScreenState();
}

class _AmbulanceHomeScreenState extends State<AmbulanceHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AmbulanceProvider>().loadRequests();
        context.read<AmbulanceProvider>().loadProfileStats();
      }
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ambulance Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<AmbulanceProvider>().loadRequests(),
          ),
        ],
      ),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.isOnline ? 'Online' : 'Offline',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: provider.isOnline ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Total Trips: ${provider.totalTrips}'),
                                Text('Rating: ${provider.averageRating.toStringAsFixed(1)} ⭐'),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await provider.toggleOnlineStatus(!provider.isOnline);
                              },
                              icon: Icon(provider.isOnline ? Icons.power_off : Icons.power),
                              label: Text(provider.isOnline ? 'Go Offline' : 'Go Online'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.isOnline ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Assignment
                if (provider.currentAssignment != null)
                  Card(
                    elevation: 4,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Assignment', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Patient: ${provider.currentAssignment!.patientName}'),
                          Text('ETA: ${provider.currentAssignment!.etaMinutes} min'),
                          Text('Location: ${provider.currentAssignment!.address}'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => provider.markArrived(),
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Mark Arrived'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Incoming Requests'),
                      subtitle: Text('${provider.assignments.length} waiting'),
                      onTap: () => Navigator.push(
                        context,
                        PageTransitions.slideFromRight(const AmbulanceRequestsScreen()),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Incoming Requests List
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.assignments.isEmpty && provider.currentAssignment == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_hospital,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    provider.isOnline
                                        ? 'Waiting for emergency calls...'
                                        : 'Go online to receive calls',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: provider.assignments.length + (provider.error != null ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == 0 && provider.error != null) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(color: Colors.red),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      provider.error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                
                                final adjustedIndex = provider.error != null ? index - 1 : index;
                                final assignment = provider.assignments[adjustedIndex];
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(assignment.patientName),
                                    subtitle: Text(assignment.address),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Chip(
                                          label: Text(assignment.priority),
                                          backgroundColor: _getPriorityColor(assignment.priority),
                                        ),
                                        Text('${assignment.etaMinutes} min'),
                                      ],
                                    ),
                                    onTap: () async {
                                      await provider.acceptRequest(assignment.id, assignment.etaMinutes);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request accepted!')),
                                      );
                                    },
                                  ),
                                );
                              },
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
