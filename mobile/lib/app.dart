import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/routes.dart';
import 'core/constants.dart';
import 'core/sensor_service.dart';
import 'features/auth/splash.dart';
import 'shared/models.dart';

class HumanSafetyApp extends StatelessWidget {
  const HumanSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => CasesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => SensorService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const _AppStartupWrapper(),
            routes: AppRoutes.getRoutes(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class _AppStartupWrapper extends StatelessWidget {
  const _AppStartupWrapper();

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class _LoadUserProfileWrapper extends StatefulWidget {
  const _LoadUserProfileWrapper();

  @override
  State<_LoadUserProfileWrapper> createState() =>
      _LoadUserProfileWrapperState();
}

class _LoadUserProfileWrapperState extends State<_LoadUserProfileWrapper> {
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final casesProvider = context.read<CasesProvider>();
      final notificationsProvider = context.read<NotificationsProvider>();
      final statsProvider = context.read<StatsProvider>();

      // Fetch user profile from server to get their role
      final response = await authProvider.fetchUserProfile();

      if (mounted && response != null) {
        final role = response['role'] as String? ?? 'user';
        final userId = response['_id'] ?? response['id'] ?? '';
        final token = authProvider.token;

        // Initialize providers with real data based on role
        if (token != null && userId.isNotEmpty) {
          if (role == 'user') {
            // Load user's cases and notifications
            try {
              await Future.wait([
                casesProvider.fetchCases(userId),
                notificationsProvider.load(userId),
              ]);
            } catch (e) {
              debugPrint('Error loading user data: $e');
            }
          } else if (role == 'admin') {
            // Load admin stats
            try {
              await statsProvider.fetchStats(token);
            } catch (e) {
              debugPrint('Error loading admin stats: $e');
            }
          }
        }

        // Navigate to appropriate home screen based on role
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            _getHomeRouteForRole(role),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  String _getHomeRouteForRole(String role) {
    switch (role) {
      case 'police':
        return AppRoutes.policeDashboard;
      case 'hospital':
        return AppRoutes.hospitalDashboard;
      case 'admin':
        return AppRoutes.adminDashboard;
      case 'user':
      default:
        return AppRoutes.userHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
