import 'package:flutter/material.dart';

/// AUTH
import '../features/auth/login.dart';
import '../features/auth/signup.dart';

/// USER
import '../features/user/home.dart';
import '../features/user/role_application.dart';
import '../features/user/sos.dart';
import '../features/user/tracking.dart';
import '../features/user/contacts.dart';
import '../features/user/report.dart';
import '../features/user/notifications.dart';
import '../features/user/profile.dart' as user_profile;

/// ADMIN
import '../features/admin/dashboard.dart';
import '../features/admin/role_verification.dart';
import '../features/admin/users.dart';
import '../features/admin/reports.dart';
import '../features/admin/analytics.dart';
import '../features/admin/profile.dart' as admin_profile;
import '../features/admin/notifications.dart' as admin_notifications;
import '../features/admin/settings.dart' as admin_settings;

/// HOSPITAL
import '../features/hospital/dashboard.dart' as hospital_dashboard;
import '../features/hospital/requests.dart';
import '../features/hospital/profile.dart' as hospital_profile;
import '../features/hospital/notifications.dart' as hospital_notifications;
import '../features/hospital/settings.dart' as hospital_settings;

/// POLICE
import '../features/police/dashboard.dart' as police_dashboard;
import '../features/police/alerts.dart' show AlertsScreen;
import '../features/police/cases.dart' as police_cases;
import '../features/police/profile.dart' as police_profile;
import '../features/police/notifications.dart' as police_notifications;
import '../features/police/settings.dart' as police_settings;

/// SETTINGS
import '../features/settings/settings.dart';
import '../features/settings/privacy.dart';
import '../features/settings/theme_mode.dart';
import '../features/settings/about.dart';
import '../features/settings/help.dart';

class AppRoutes {
  /// AUTH
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  /// USER
  static const String userHome = '/user/home';
  static const String roleApplication = '/user/role-application';
  static const String sos = '/user/sos';
  static const String tracking = '/user/tracking';
  static const String contacts = '/user/contacts';
  static const String report = '/user/report';
  static const String notifications = '/user/notifications';
  static const String profile = '/user/profile';

  /// ADMIN
  static const String adminDashboard = '/admin/dashboard';
  static const String adminRoleVerification = '/admin/role-verification';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminProfile = '/admin/profile';
  static const String adminNotifications = '/admin/notifications';
  static const String adminSettings = '/admin/settings';

  /// HOSPITAL
  static const String hospitalDashboard = '/hospital/dashboard';
  static const String hospitalRequests = '/hospital/requests';
  static const String hospitalAmbulance = '/hospital/ambulance';
  static const String hospitalCases = '/hospital/cases';
  static const String hospitalProfile = '/hospital/profile';
  static const String hospitalNotifications = '/hospital/notifications';
  static const String hospitalSettings = '/hospital/settings';

  /// POLICE
  static const String policeDashboard = '/police/dashboard';
  static const String policeAlerts = '/police/alerts';
  static const String policeCases = '/police/cases';
  static const String policeProfile = '/police/profile';
  static const String policeNotifications = '/police/notifications';
  static const String policeSettings = '/police/settings';

  /// SETTINGS
  static const String settings = '/settings';
  static const String privacy = '/privacy';
  static const String themeMode = '/theme-mode';
  static const String about = '/about';
  static const String help = '/help';

  static String getHomeRouteForRole(String role) {
    switch (role) {
      case 'police':
        return policeDashboard;
      case 'hospital':
        return hospitalDashboard;
      case 'admin':
        return adminDashboard;
      case 'user':
      default:
        return userHome;
    }
  }

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      /// AUTH
      login: (_) => const LoginScreen(),
      signup: (_) => const SignupScreen(),

      /// USER
      userHome: (_) => const UserHomeScreen(),
      roleApplication: (_) => const RoleApplicationScreen(),
      sos: (_) => const SOSScreen(),
      tracking: (_) => const TrackingScreen(),
      contacts: (_) => const ContactsScreen(),
      report: (_) => const ReportScreen(),
      notifications: (_) => const NotificationsScreen(),
      profile: (_) => const user_profile.ProfileScreen(),

      /// ADMIN
      adminDashboard: (_) => const AdminDashboardScreen(),
      adminRoleVerification: (_) => const RoleVerificationScreen(),
      adminUsers: (_) => const AdminUsersScreen(),
      adminReports: (_) => const AdminReportsScreen(),
      adminAnalytics: (_) => const AdminAnalyticsScreen(),
      adminProfile: (_) => const admin_profile.AdminProfileScreen(),
      adminNotifications: (_) =>
          const admin_notifications.AdminNotificationsScreen(),
      adminSettings: (_) => const admin_settings.SettingsScreen(),

      /// HOSPITAL
      hospitalDashboard: (_) => const hospital_dashboard.DashboardScreen(),
      hospitalRequests: (_) => const RequestsScreen(),
      hospitalAmbulance: (_) => const AmbulanceScreen(),
      hospitalCases: (_) => const HospitalCasesScreen(),
      hospitalProfile: (_) => const hospital_profile.ProfileScreen(),
      hospitalNotifications: (_) =>
          const hospital_notifications.HospitalNotificationsScreen(),
      hospitalSettings: (_) => const hospital_settings.HospitalSettingsScreen(),

      /// POLICE
      policeDashboard: (_) => const police_dashboard.DashboardScreen(),
      policeAlerts: (_) => const AlertsScreen(),
      policeCases: (_) => const police_cases.CasesScreen(),
      policeProfile: (_) => const police_profile.ProfileScreen(),
      policeNotifications: (_) =>
          const police_notifications.PoliceNotificationsScreen(),
      policeSettings: (_) => const police_settings.PoliceSettingsScreen(),

      /// SETTINGS
      settings: (_) => const SettingsScreen(),
      privacy: (_) => const PrivacyScreen(),
      themeMode: (_) => const ThemeModeScreen(),
      about: (_) => const AboutScreen(),
      help: (_) => const HelpScreen(),
    };
  }
}
