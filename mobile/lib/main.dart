import 'package:flutter/material.dart';
import 'app.dart';
import 'core/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const HumanSafetyApp());
}
