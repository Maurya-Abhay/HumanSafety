import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _sosActive = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Emergency SOS'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  if (_sosActive)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'SOS Activated',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Help is on the way'),
                        const SizedBox(height: 30),
                      ],
                    ),
                  if (!_sosActive)
                    Column(
                      children: [
                        const Text(
                          'Emergency SOS',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text('Tap the SOS button for immediate help'),
                        const SizedBox(height: 50),
                      ],
                    ),
                  SOSButton(
                    isActive: _sosActive,
                    onPressed: () async {
                      if (_sosActive) {
                        setState(() => _sosActive = false);
                      } else {
                        setState(() => _isLoading = true);
                        await context.read<CasesProvider>().reportSOS({
                          'type': 'emergency',
                          'timestamp': DateTime.now().toIso8601String(),
                        });
                        if (mounted) {
                          setState(() {
                            _sosActive = true;
                            _isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            if (_sosActive) ...[
              const Divider(),
              const SizedBox(height: 20),
              Text(
                'Emergency Contacts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CustomCard(
                child: ListTile(
                  leading: const Icon(Icons.call, color: AppColors.accent),
                  title: const Text('Police'),
                  subtitle: const Text('Emergency services'),
                  trailing: const Icon(Icons.call_made),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                child: ListTile(
                  leading: const Icon(Icons.call, color: AppColors.info),
                  title: const Text('Ambulance'),
                  subtitle: const Text('Medical emergency'),
                  trailing: const Icon(Icons.call_made),
                  onTap: () {},
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
