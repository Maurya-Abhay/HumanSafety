import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/routes.dart';
import 'core/constants.dart';
import 'shared/models.dart';
import 'features/user/home.dart';
import 'features/admin/dashboard.dart';
import 'features/police/dashboard.dart' as police;
import 'features/hospital/dashboard.dart' as hospital;

class HumanSafetyApp extends StatelessWidget {
  const HumanSafetyApp({Key? key}) : super(key: key);

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // FIXED: home + routes "/" conflict removed
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.getRoutes(),

            // Dynamic first screen handler
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.splash) {
                return MaterialPageRoute(
                  builder: (_) => _buildHome(context),
                );
              }
              return null;
            },

            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return const _SplashWrapper();
    }

    // Load user profile from server to get role
    return _LoadUserProfileWrapper();
  }

  Widget _buildRoleSpecificHome(String role) {
    switch (role) {
      case 'user':
        return const UserHomeScreen();

      case 'police':
        return const police.DashboardScreen();

      case 'hospital':
        return const hospital.DashboardScreen();

      case 'admin':
        return const AdminDashboardScreen();

      default:
        return const UserHomeScreen();
    }
  }
}

class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_outlined, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your Safety, Our Priority',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadUserProfileWrapper extends StatefulWidget {
  @override
  State<_LoadUserProfileWrapper> createState() => _LoadUserProfileWrapperState();
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
              print('Error loading user data: $e');
            }
          } else if (role == 'admin') {
            // Load admin stats
            try {
              await statsProvider.fetchStats(token);
            } catch (e) {
              print('Error loading admin stats: $e');
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
      print('Error loading profile: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  String _getHomeRouteForRole(String role) {
    switch (role) {
      case 'police':
        return '/police-home';
      case 'hospital':
        return '/hospital-home';
      case 'admin':
        return '/admin-home';
      case 'user':
      default:
        return '/user-home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}