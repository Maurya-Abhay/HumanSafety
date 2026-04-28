import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        'id': '1',
        'title': 'Medical Emergency',
        'type': 'accident',
        'status': 'resolved',
        'date': '2024-01-15'
      },
      {
        'id': '2',
        'title': 'Security Incident',
        'type': 'theft',
        'status': 'active',
        'date': '2024-01-16'
      },
      {
        'id': '3',
        'title': 'Traffic Accident',
        'type': 'accident',
        'status': 'resolved',
        'date': '2024-01-14'
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reports'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report['title']!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: report['status'] == 'active' ? AppColors.warning : AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report['status']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Type: ${report['type']}', style: const TextStyle(fontSize: 14)),
                      Text('Date: ${report['date']}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
