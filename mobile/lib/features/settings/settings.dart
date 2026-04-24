import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.themeMode),
              child: ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
              child: const ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Privacy & Security'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              child: const ListTile(
                leading: Icon(Icons.info),
                title: Text('About App'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.help),
              child: const ListTile(
                leading: Icon(Icons.help),
                title: Text('Help & Support'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
