import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'accident';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Report Incident'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Incident Type',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              onChanged: (value) => setState(() => _selectedType = value ?? 'accident'),
              items: ['accident', 'theft', 'harassment', 'other']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Title',
              hint: 'Brief title of the incident',
              controller: _titleController,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Description',
              hint: 'Detailed description',
              controller: _descriptionController,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            Text(
              'Additional Info',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('Current Location'),
                subtitle: const Text('45.34° N, 75.42° W'),
                trailing: const Icon(Icons.check_circle, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                title: const Text('Add Photos'),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Submit Report',
              isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);
                await context.read<CasesProvider>().reportIncident({
                  'title': _titleController.text,
                  'description': _descriptionController.text,
                  'type': _selectedType,
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
