import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Analytics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                  _buildMetricRow('Response Time', '4.2 min', 'avg'),
                  const SizedBox(height: 12),
                  _buildMetricRow('Case Resolution', '92%', 'rate'),
                  const SizedBox(height: 12),
                  _buildMetricRow('User Satisfaction', '4.6/5', 'stars'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Daily Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: AppColors.grey),
                    SizedBox(height: 12),
                    Text('Chart View'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                  _buildTrendRow('Monday', 15, 14),
                  _buildTrendRow('Tuesday', 12, 11),
                  _buildTrendRow('Wednesday', 18, 17),
                  _buildTrendRow('Thursday', 10, 9),
                  _buildTrendRow('Friday', 16, 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(unit, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTrendRow(String day, int incidents, int resolved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day),
          Row(
            children: [
              Chip(
                label: Text('$incidents incidents'),
                backgroundColor: AppColors.warning.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('$resolved resolved'),
                backgroundColor: AppColors.success.withOpacity(0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
