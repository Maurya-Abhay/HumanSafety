import 'package:flutter/material.dart';
import 'app.dart';
import 'core/storage_service.dart';
import 'core/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await BackgroundService.initialize();
  runApp(const HumanSafetyApp());
}
