import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';

class ThemeModeScreen extends StatelessWidget {
  const ThemeModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Theme'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Choose Theme',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                CustomCard(
                  onTap: () => themeProvider.setTheme(false),
                  backgroundColor: !themeProvider.isDarkMode ? AppColors.greyLight : null,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.greyLight,
                        ),
                        child: const Icon(Icons.light_mode, color: Colors.orange, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Light Mode',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      if (!themeProvider.isDarkMode)
                        const Text(
                          'Selected',
                          style: TextStyle(fontSize: 12, color: AppColors.success),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomCard(
                  onTap: () => themeProvider.setTheme(true),
                  backgroundColor: themeProvider.isDarkMode ? AppColors.greyLight : null,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.greyDark,
                        ),
                        child: const Icon(Icons.dark_mode, color: Colors.blueGrey, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Dark Mode',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      if (themeProvider.isDarkMode)
                        const Text(
                          'Selected',
                          style: TextStyle(fontSize: 12, color: AppColors.success),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
