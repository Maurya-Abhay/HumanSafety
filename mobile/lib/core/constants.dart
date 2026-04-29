import 'package:flutter/material.dart';

class AppConstants {
  // API
  static const String baseUrl = 'https://humansafety.onrender.com';
  static const String wsUrl = 'wss://humansafety.onrender.com';
  static const String apiVersion = '/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String loginTimeKey = 'login_time';
  static const String roleKey = 'user_role';
  static const String themeKey = 'theme_mode';
  static const String emergencyContactsKey = 'emergency_contacts';

  // Strings
  static const String appName = 'HumanSafety';
  static const String appVersion = '1.0.0';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxPhoneLength = 15;
}

enum UserRole { user, police, hospital, admin }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.police:
        return 'Police';
      case UserRole.hospital:
        return 'Hospital';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Regular User';
      case UserRole.police:
        return 'Police Officer';
      case UserRole.hospital:
        return 'Hospital Staff';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.user:
        return const Color(0xFF2E7D32);
      case UserRole.police:
        return const Color(0xFF1976D2);
      case UserRole.hospital:
        return const Color(0xFFD32F2F);
      case UserRole.admin:
        return const Color(0xFF7B1FA2);
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.user:
        return Icons.person;
      case UserRole.police:
        return Icons.security;
      case UserRole.hospital:
        return Icons.local_hospital;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }
}
