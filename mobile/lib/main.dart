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
  await EnvConfig.initialize();
  EnvConfig.debugPrint('API Base URL: ${EnvConfig.apiBaseUrl}');
  EnvConfig.debugPrint('WebSocket URL: ${EnvConfig.wsBaseUrl}');
  
  await StorageService.init();
  await ButtonListenerService().initialize();
  await BackgroundService.initialize();
  await EmergencyOrchestrator().initialize();
  await AudioService().initialize();
  await PortalSoundService().initialize();
  await PermissionService.requestEssentialPermissions();
  runApp(const HumanSafetyApp());
}
