import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';

class ThemeModeScreen extends StatelessWidget {
  const ThemeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Background color based on theme for that premium depth
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(title: 'Appearance'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Choose Your Style',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customize how the app looks on your device.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),

                // Theme Grid Layout for a balanced look
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        icon: Icons.wb_sunny_rounded,
                        activeGradient: const [
                          Color(0xFFFF9900),
                          Color(0xFFFFCC00)
                        ],
                        title: 'Light',
                        isSelected: !themeProvider.isDarkMode,
                        onTap: () => themeProvider.setTheme(false),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        icon: Icons.nights_stay_rounded,
                        activeGradient: const [
                          Color(0xFF6A11CB),
                          Color(0xFF2575FC)
                        ],
                        title: 'Dark',
                        isSelected: themeProvider.isDarkMode,
                        onTap: () => themeProvider.setTheme(true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Modern Auto-Save Indicator
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16,
                            color:
                                isDark ? Colors.amber[200] : Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Settings are applied instantly',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required List<Color> activeGradient,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(2), // Space for the selection border
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected ? LinearGradient(colors: activeGradient) : null,
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: activeGradient[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          child: Column(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? activeGradient[0].withOpacity(0.1)
                      : (isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.04)),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? activeGradient[0]
                      : (isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 12),
              // Check Indicator
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeGradient[0],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
