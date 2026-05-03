import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/routes.dart';
import 'core/navigation_service.dart';
import 'core/hardware_sos_controller.dart';
import 'core/constants.dart';
import 'core/emergency_orchestrator.dart';
import 'core/sensor_service.dart';
import 'core/audio_service.dart';
import 'core/portal_sound_service.dart';
import 'core/sos_launch_controller.dart';
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
        ChangeNotifierProvider(create: (_) => EmergencyOrchestrator()),
        ChangeNotifierProvider(create: (_) => SensorService()),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => PortalSoundService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDarkMode = themeProvider.isDarkMode;
          final systemBarColor = isDarkMode ? const Color(0xFF15161A) : Colors.white;

          return MaterialApp(
            title: AppConstants.appName,
            navigatorKey: AppNavigationService.navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDarkMode ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      isDarkMode ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: systemBarColor,
                  systemNavigationBarIconBrightness:
                      isDarkMode ? Brightness.light : Brightness.dark,
                  systemNavigationBarDividerColor: systemBarColor,
                  systemNavigationBarContrastEnforced: false,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _AppStartupWrapper(),
            routes: AppRoutes.getRoutes(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class _AppStartupWrapper extends StatefulWidget {
  const _AppStartupWrapper();

  @override
  State<_AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends State<_AppStartupWrapper> {
  @override
  void initState() {
    super.initState();
    // Check if app was launched due to SOS trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sosController = SosLaunchController();
      if (sosController.shouldShowSosImmediately) {
        sosController.consumed();
        final source = sosController.triggerSource ?? 'volume_down';
        // Arm the SOS and navigate directly to SOS screen
        HardwareSosController.arm(source);
        AppNavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.sos,
          (route) => false, // Remove all previous routes
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Skip splash screen entirely - go straight to login/home based on auth state
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          // User is logged in - show home for their role
          final role = authProvider.user?.role ?? 'user';
          final homeRoute = AppRoutes.getHomeRouteForRole(role);
          
          // Navigate to home and remove splash from stack
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, homeRoute);
          });
        } else {
          // User not authenticated - show login screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          });
        }

        // Return minimal blank screen while routing
        return const Scaffold(
          backgroundColor: Color(0xFF0A0E21),
          body: SizedBox.shrink(),
        );
      },
    );
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
