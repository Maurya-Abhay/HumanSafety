import 'package:flutter/material.dart';
import 'dart:ui';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Assistance Live',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_location_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Ambient Glow
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PREMIUM MAP VIEW ---
                _buildModernMapSection(size, isDark),

                const SizedBox(height: 24),

                // --- LIVE STATUS CARD ---
                _buildLiveStatusCard(isDark),

                const SizedBox(height: 32),

                // --- RESPONDERS SECTION ---
                const Row(
                  children: [
                    Icon(Icons.directions_run_rounded,
                        size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      "Nearby Responders",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernResponderTile(
                  icon: Icons.local_police_rounded,
                  title: "Police Unit - P442",
                  subtitle: "Enroute • 2.5 km away",
                  eta: "5 min",
                  color: Colors.blueAccent,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildModernResponderTile(
                  icon: Icons.medical_services_rounded,
                  title: "Ambulance - Medic 9",
                  subtitle: "Dispatched • 3.2 km away",
                  eta: "8 min",
                  color: Colors.redAccent,
                  isDark: isDark,
                ),

                const SizedBox(height: 32),

                // --- INCIDENT DETAILS BENTO ---
                const Text(
                  "Incident Context",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                _buildIncidentBento(isDark),

                const SizedBox(height: 30),

                // --- DANGER ZONE ACTIONS ---
                _buildCancelButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMapSection(Size size, bool isDark) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Mock Map Background
            Container(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              child: Center(
                child: Icon(Icons.map_rounded,
                    size: 80, color: isDark ? Colors.white10 : Colors.black12),
              ),
            ),

            // Pulsing Marker Logic
            Center(
              child: _buildRippleAnimation(),
            ),

            // Map Overlay Info
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.05 : 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Sector 42, Green Park, Delhi",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusStep(true, "Alert", isDark),
              _buildStatusConnector(true),
              _buildStatusStep(true, "Rescue", isDark),
              _buildStatusConnector(false),
              _buildStatusStep(false, "Arrived", isDark),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Rescue teams have been notified and are on the way.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildStatusStep(bool completed, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
                color: completed
                    ? AppColors.primary
                    : Colors.grey.withOpacity(0.5),
                width: 2),
          ),
          child: Icon(
            completed ? Icons.check : Icons.circle,
            size: 16,
            color: completed ? Colors.white : Colors.grey.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: completed ? FontWeight.w900 : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStatusConnector(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [AppColors.primary, AppColors.primary]
                : [AppColors.primary, Colors.grey.withOpacity(0.2)],
          ),
        ),
      ),
    );
  }

  Widget _buildModernResponderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String eta,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Text(eta,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentBento(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _bentoRow(Icons.bolt_rounded, "Emergency Type",
              "High Impact Collision", Colors.orange),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1)),
          _bentoRow(Icons.timer_rounded, "Time Since Alert", "02:45 min",
              Colors.blue),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1)),
          _bentoRow(Icons.battery_charging_full_rounded, "Device Status",
              "84% Battery • Online", Colors.green),
        ],
      ),
    );
  }

  Widget _bentoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildCancelButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: TextButton(
        onPressed: () {},
        child: const Text(
          "CANCEL ALERT (I AM SAFE)",
          style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
              letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildRippleAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _rippleCircle(100, 0.1),
        _rippleCircle(150, 0.05),
        const Icon(Icons.circle, color: Colors.redAccent, size: 16),
      ],
    );
  }

  Widget _rippleCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.redAccent.withOpacity(opacity),
      ),
    );
  }
}
