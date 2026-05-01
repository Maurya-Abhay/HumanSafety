import 'package:flutter/material.dart';
import 'app.dart';
import 'core/env_config.dart';
import 'core/storage_service.dart';
import 'core/background_service.dart';
import 'core/emergency_orchestrator.dart';
import 'core/audio_service.dart';
import 'core/portal_sound_service.dart';
import 'core/permission_service.dart';
import 'core/button_listener_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration first
  // Essential initialization only (keep startup fast)
  await EnvConfig.initialize();
  EnvConfig.debugPrint('API Base URL: ${EnvConfig.apiBaseUrl}');
  EnvConfig.debugPrint('WebSocket URL: ${EnvConfig.wsBaseUrl}');

  // Storage is required early for settings; initialize before UI
  await StorageService.init();

  // Start the app immediately; defer heavy/nonessential inits
  runApp(const HumanSafetyApp());

  // Initialize background services without blocking UI
  Future.microtask(() async {
    try {
      // Lightweight listener for hardware buttons (important)
      ButtonListenerService().initialize();

      // Non-UI background tasks
      BackgroundService.initialize();
      EmergencyOrchestrator().initialize();

      // Audio and portal sound can initialize lazily; run in background
      AudioService().initialize();
      PortalSoundService().initialize();

      // Request essential permissions in background (will prompt UI when needed)
      PermissionService.requestEssentialPermissions();
    } catch (e) {
      // Don't crash the app if background init fails
      debugPrint('Background init error: $e');
    }
  });
}
