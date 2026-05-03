import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/page_transitions.dart';
import '../../core/constants.dart';
import './sos.dart' show SOSScreen;
import './contacts.dart';
import './profile.dart';
import './notifications.dart';
import '../settings/settings.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      // --- TERA ORIGINAL HEADER RESTORED ---
      appBar: CustomAppBar(
        title: AppConstants.appName,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, PageTransitions.slideFromRight(const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, PageTransitions.slideFromRight(const ProfileScreen())),
          ),
        ],
      ),
      
      // --- NEXT LEVEL BODY DESIGN ---
      body: Stack(
        children: [
          // Background Glow for Depth
          _buildBackgroundGlow(size),
          
          _buildBody(isDark),
        ],
      ),

      // --- TERA ORIGINAL FOOTER RESTORED WITH LOGIC ---
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) PageTransitions.replaceSmooth(context, const SOSScreen());
          if (index == 2) PageTransitions.replaceSmooth(context, const ContactsScreen());
          if (index == 3) PageTransitions.replaceSmooth(context, const SettingsScreen());
        },
        items: [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.warning_amber_rounded, label: 'SOS'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- GREETING SECTION ---
          _buildGreeting(),
          
          const SizedBox(height: 25),

          // --- ULTRA PRO SOS CARD (Instant Action) ---
          _buildPremiumSOSCard(),

          const SizedBox(height: 30),

          // --- BENTO GRID (EMERGENCY SERVICES) ---
          const Text(
            'Intelligence Hub',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          
          _buildBentoGrid(),

          const SizedBox(height: 32),

          // --- RECENT CASES SECTION ---
          _buildRecentCasesHeader(),
          const SizedBox(height: 12),

          Consumer<CasesProvider>(
            builder: (context, casesProvider, _) {
              if (casesProvider.isLoading) return const Center(child: CircularProgressIndicator());
              if (casesProvider.cases.isEmpty) return _buildEmptyState();
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: casesProvider.cases.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildModernCaseCard(casesProvider.cases[index], isDark);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- REFINED UI COMPONENTS ---

  Widget _buildGreeting() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final fullName = auth.user?.name.trim() ?? '';
        final displayName = fullName.isEmpty ? 'User' : fullName.split(' ').first;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PROTECTION ACTIVE",
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Text("Hello, $displayName",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
              ],
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(
                displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildPremiumSOSCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFF9F1239)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("EMERGENCY SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                SizedBox(height: 4),
                Text("Tap to alert nearest police & hospital", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.sos),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: Colors.red,
              shape: const CircleBorder(), padding: const EdgeInsets.all(15),
            ),
            child: const Icon(Icons.power_settings_new_rounded, size: 30),
          )
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _bentoItem("Live Tracking", Icons.gps_fixed_rounded, Colors.blue, AppRoutes.tracking),
        _bentoItem("File Report", Icons.edit_document, Colors.orange, AppRoutes.report),
        _bentoItem("Safe Zone", Icons.verified_user_rounded, Colors.green, AppRoutes.roleApplication),
        _bentoItem("Contacts", Icons.people_alt_rounded, Colors.purple, AppRoutes.contacts),
      ],
    );
  }

  Widget _bentoItem(String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCaseCard(Case case_, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(case_.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(case_.status, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildRecentCasesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recent Protection Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text("View All")),
      ],
    );
  }

  Widget _buildBackgroundGlow(Size size) {
    return Positioned(
      top: 0, right: 0,
      child: Container(
        width: size.width * 0.7, height: size.height * 0.3,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.1), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No logs found. You are safe!"));
  }
}