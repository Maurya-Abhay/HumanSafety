import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/env_config.dart';
import 'core/background_service.dart';
import 'core/emergency_orchestrator.dart';
import 'core/audio_service.dart';
import 'core/portal_sound_service.dart';
import 'core/permission_service.dart';
import 'core/button_listener_service.dart';
import 'core/app_config.dart';
import 'core/cached_http_client.dart';
import 'core/complete_api_service.dart';
import 'core/theme.dart';
import 'core/sensor_service.dart';
import 'shared/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF15161A),
    systemNavigationBarDividerColor: Color(0xFF15161A),
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  // Set portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EnvConfig.initialize();
  debugPrint('✅ Env config initialized: ${EnvConfig.apiBaseUrl}');

  // Initialize app
  runApp(const HumanSafetyApp());

  // Defer heavy initialization
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 500), () async {
      await _initializeServices();
    });
  });
}

Future<void> _initializeServices() async {
  try {
    // Configure API service
    ApiService().setBaseUrl(EnvConfig.apiBaseUrl);

    // Initialize non-blocking background services
    ButtonListenerService().initialize();
    BackgroundService.initialize();
    EmergencyOrchestrator().initialize();
    AudioService().initialize();
    PortalSoundService().initialize();

    // Request permissions asynchronously
    await Future.delayed(const Duration(milliseconds: 1000));
    PermissionService.requestEssentialPermissions();

    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('❌ Service initialization error: $e');
  }
}

// Theme Provider class in models.dart - imported from shared/models.dart via provider setup
