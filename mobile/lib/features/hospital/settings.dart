import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/storage_service.dart';
import '../../core/theme.dart';

class HospitalSettingsScreen extends StatefulWidget {
  const HospitalSettingsScreen({super.key});

  @override
  State<HospitalSettingsScreen> createState() => _HospitalSettingsScreenState();
}

class _HospitalSettingsScreenState extends State<HospitalSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _emergencyAlertsEnabled = true;
  bool _ambulanceTrackingEnabled = true;
  bool _updatingBeds = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final darkMode = await StorageService.getBool('darkMode') ?? false;
    final notifications = await StorageService.getBool('notifications') ?? true;
    final emergencyAlerts = await StorageService.getBool('emergencyAlerts') ?? true;
    final ambulanceTracking = await StorageService.getBool('ambulanceTracking') ?? true;

    if (!mounted) return;
    setState(() {
      _darkModeEnabled = darkMode;
      _notificationsEnabled = notifications;
      _emergencyAlertsEnabled = emergencyAlerts;
      _ambulanceTrackingEnabled = ambulanceTracking;
    });
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        content: const Text(
          'Your data is securely stored and only used for emergency response and patient care purposes.',
          style: TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        centerTitle: false,
        title: Text(
          'Control Settings',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : const Color(0xFF475569)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: Icon(Icons.person_outline_rounded, color: isDark ? Colors.white : const Color(0xFF475569)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 24),
          _buildSectionHeader('Emergency System'),
          const SizedBox(height: 10),
          _buildToggleItem(
            'Emergency Alerts',
            'Instant critical notifications for new alerts',
            _emergencyAlertsEnabled,
            (value) {
              setState(() => _emergencyAlertsEnabled = value);
              StorageService.saveBool('emergencyAlerts', value);
            },
            Icons.emergency_rounded,
            isDark,
          ),
          _buildToggleItem(
            'Ambulance Tracking',
            'Real-time live positioning access',
            _ambulanceTrackingEnabled,
            (value) {
              setState(() => _ambulanceTrackingEnabled = value);
              StorageService.saveBool('ambulanceTracking', value);
            },
            Icons.directions_car_rounded,
            isDark,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Hospital Capacity'),
          const SizedBox(height: 10),
          _buildCapacityCard(isDark),
          const SizedBox(height: 24),
          _buildSectionHeader('App Preferences'),
          const SizedBox(height: 10),
          _buildToggleItem(
            'Push Notifications',
            'Updates regarding system activities',
            _notificationsEnabled,
            (value) {
              setState(() => _notificationsEnabled = value);
              StorageService.saveBool('notifications', value);
            },
            Icons.notifications_active_rounded,
            isDark,
          ),
          _buildToggleItem(
            'Dark Mode Theme',
            'Easier on the eyes in low light',
            _darkModeEnabled,
            (value) {
              setState(() => _darkModeEnabled = value);
              StorageService.saveBool('darkMode', value);
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
            Icons.dark_mode_rounded,
            isDark,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support & Legal'),
          const SizedBox(height: 10),
          _buildNavigationItem(
            'Privacy Policy',
            'How we treat user and patient data',
            Icons.privacy_tip_rounded,
            _showPrivacyPolicy,
            isDark,
          ),
          _buildNavigationItem(
            'Help & Technical Support',
            'Contact system administrators',
            Icons.support_agent_rounded,
            () {},
            isDark,
          ),
          const SizedBox(height: 36),
          _buildLogoutButton(isDark),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, 
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.hospitalDashboard);
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.hospitalRequests);
          if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.hospitalAmbulance);
          if (index == 3) return;
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency_rounded, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car_rounded, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.tune_rounded, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital Control Center',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.4),
                ),
                SizedBox(height: 4),
                  Text(
                    'Tune alerts, tracking, and system behavior directly.',
                    style: TextStyle(color: AppColors.whiteBorders, fontSize: 12, height: 1.3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCapacityCard(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final totalBeds = user?.totalBeds ?? 0;
        final availableBeds = user?.availableBeds ?? 0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(isDark ? 0.08 : 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Availability', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$availableBeds / $totalBeds Beds',
                      style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Keep availability updated so critical dispatch remains accurate.',
                style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _updateBedsDialog(auth, totalBeds, availableBeds),
                  icon: _updatingBeds ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: Text(_updatingBeds ? 'Updating...' : 'Update Available Beds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(isDark ? 0.08 : 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withOpacity(0.35),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(isDark ? 0.08 : 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF64748B).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDark ? Colors.white : const Color(0xFF475569), size: 20),
        ),
        title: Text(
          title, 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return OutlinedButton.icon(
      onPressed: () async {
        await StorageService.clear();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      },
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Log Out From System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444),
        side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5),
        backgroundColor: const Color(0xFFFFFAFA),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _updateBedsDialog(AuthProvider auth, int totalBeds, int currentBeds) async {
    final controller = TextEditingController(text: currentBeds.toString());
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Bed Availability', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter exact total current available beds:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                helperText: 'Capacity ceiling: Max $totalBeds',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == null) return;
    if (confirmed < 0 || confirmed > totalBeds) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid bed count'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    try {
      setState(() => _updatingBeds = true);
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        await ApiService.updateHospitalBeds(token, confirmed);
        final currentUser = auth.user;
        if (currentUser != null) {
          auth.updateUser(currentUser.copyWith(availableBeds: confirmed));
        }
      }
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Bed capacity successfully updated'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _updatingBeds = false);
    }
  }
}

// (removed invalid Colors extension) Using `AppColors.whiteBorders` from core/theme.dart