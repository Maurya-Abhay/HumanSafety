import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/env_config.dart';
import 'core/background_service.dart';
import 'core/emergency_orchestrator.dart';
import 'core/audio_service.dart';
import 'core/portal_sound_service.dart';
import 'core/permission_service.dart';
import 'core/button_listener_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF15161A),
    systemNavigationBarDividerColor: Color(0xFF15161A),
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  // Start the app immediately; defer all inits until app is fully rendered.
  runApp(const HumanSafetyApp());

  // Defer everything: env config, background services, audio, sensors.
  // This lets the first frame render almost instantly.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Load env config in background (not blocking UI).
        await EnvConfig.initialize();
        EnvConfig.debugPrint('API Base URL: ${EnvConfig.apiBaseUrl}');
        EnvConfig.debugPrint('WebSocket URL: ${EnvConfig.wsBaseUrl}');
      } catch (e) {
        debugPrint('Env init error: $e');
      }

      try {
        // Initialize non-blocking background services after UI settles.
        ButtonListenerService().initialize();
        BackgroundService.initialize();
        EmergencyOrchestrator().initialize();
        AudioService().initialize();
        PortalSoundService().initialize();
        PermissionService.requestEssentialPermissions();
      } catch (e) {
        debugPrint('Background init error: $e');
      }
    });
  });
}
