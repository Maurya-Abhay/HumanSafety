import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Alerts'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            child: ListTile(
              leading: const Icon(Icons.warning, color: AppColors.warning),
              title: const Text('Alert'),
              subtitle: const Text('5 mins ago'),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('Respond'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CasesScreen extends StatelessWidget {
  const CasesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Cases'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            child: ListTile(
              leading: const Icon(Icons.description, color: AppColors.primary),
              title: Text('Case #${1000 + index}'),
              subtitle: const Text('Status: Active'),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        ),
      ),
    );
  }
}

class PatrolScreen extends StatelessWidget {
  const PatrolScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Patrol'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
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
                    Icon(Icons.map, size: 48, color: AppColors.grey),
                    SizedBox(height: 12),
                    Text('Live Patrol Map'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Officers on Duty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: const Text('Officer John'),
                subtitle: const Text('Zone A - Active'),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: const Text('Officer Sarah'),
                subtitle: const Text('Zone B - Active'),
              ),
            ),
          ],
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
      appBar: const CustomAppBar(title: 'Police Profile'),
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
              child: const Icon(Icons.local_police, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Police Department',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Public Safety Unit', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 32),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('Station'),
                subtitle: const Text('Central Police Station'),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.phone, color: AppColors.primary),
                title: const Text('Emergency Line'),
                subtitle: const Text('+1 (555) 911-0000'),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.email, color: AppColors.primary),
                title: const Text('Email'),
                subtitle: const Text('police@department.gov'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
