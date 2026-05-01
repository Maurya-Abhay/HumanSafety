import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestEssentialPermissions() async {
    try {
      final permissions = <Permission>[
        Permission.locationWhenInUse,
        Permission.microphone,
      ];

      if (Platform.isAndroid) {
        permissions.add(Permission.locationAlways);
        permissions.add(Permission.notification);
        permissions.add(Permission.sms);
      }

      for (final permission in permissions) {
        final status = await permission.status;
        if (status.isDenied || status.isRestricted || status.isLimited) {
          await permission.request();
        }
      }
    } catch (e) {
      debugPrint('PermissionService error: $e');
    }
  }
}