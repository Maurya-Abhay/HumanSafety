import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Emergency Requests'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            child: ListTile(
              leading: const Icon(Icons.emergency_share, color: AppColors.accent),
              title: const Text('Emergency Request'),
              subtitle: const Text('5 mins ago'),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('Accept'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AmbulanceScreen extends StatelessWidget {
  const AmbulanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Ambulance Fleet'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: AppColors.success),
              title: Text('Ambulance ${index + 1}'),
              subtitle: const Text('Ready for deployment'),
              trailing: const Chip(label: Text('Available')),
            ),
          ),
        ),
      ),
    );
  }
}

class HospitalCasesScreen extends StatelessWidget {
  const HospitalCasesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Cases'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            child: ListTile(
              leading: const Icon(Icons.medical_services, color: AppColors.info),
              title: Text('Patient Case ${index + 1}'),
              subtitle: const Text('Status: In Treatment'),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Hospital Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: const Icon(Icons.local_hospital, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'City General Hospital',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Emergency Care Provider', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 32),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('Address'),
                subtitle: const Text('123 Hospital St, City'),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.phone, color: AppColors.primary),
                title: const Text('Phone'),
                subtitle: const Text('+1 (555) 123-4567'),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.email, color: AppColors.primary),
                title: const Text('Email'),
                subtitle: const Text('contact@hospital.com'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
