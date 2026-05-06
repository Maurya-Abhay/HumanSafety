import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';

class AmbulanceCurrentCaseScreen extends StatefulWidget {
  const AmbulanceCurrentCaseScreen({super.key});

  @override
  State<AmbulanceCurrentCaseScreen> createState() => _AmbulanceCurrentCaseScreenState();
}

class _AmbulanceCurrentCaseScreenState extends State<AmbulanceCurrentCaseScreen> {
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Current Case'),
      body: Consumer<AmbulanceProvider>(
        builder: (context, provider, _) {
          final assignment = provider.currentAssignment;
          if (assignment == null) {
            return Center(
              child: Text(
                'No active case',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient: ${assignment.patientName}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Location: ${assignment.address}'),
                const SizedBox(height: 12),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ETA: ${assignment.etaMinutes} min'),
                                Text('Status: ${assignment.status}'),
                                Text('Priority: ${assignment.priority}'),
                              ],
                            ),
                            Chip(
                              label: Text(
                                '${assignment.priority.toUpperCase()}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: assignment.priority == 'critical' ? Colors.red : Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.markArrived(),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Mark as Arrived'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                const SizedBox(height: 12),
                // Complete Case Form
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Complete Case', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _conditionController,
                          decoration: InputDecoration(
                            hintText: 'Patient condition',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _treatmentController,
                          decoration: InputDecoration(
                            hintText: 'Treatment given',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await provider.completeAssignment(
                                _conditionController.text,
                                _treatmentController.text,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Case completed!')),
                                );
                                _conditionController.clear();
                                _treatmentController.clear();
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Complete Case'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }
}
