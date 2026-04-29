import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse controller for the "Breathing Glow" effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn)),
    );

    _mainController.forward();

    // Navigation logic: wait a few seconds then route based on saved session
    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // If auth is still initializing, wait briefly (up to ~2s)
      int tries = 0;
      while (auth.isInitializing && tries < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        tries++;
      }

      if (!mounted) return;
      if (auth.isAuthenticated) {
        final role = auth.user?.role ?? 'user';
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.getHomeRouteForRole(role),
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Deep premium dark background
      body: Stack(
        children: [
          // 1. Dynamic Animated Background (Mesh Effect)
          const Positioned.fill(child: _AnimatedMeshBackground()),

          // 2. Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Shield with Breathing Glow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.3 * _pulseController.value),
                              blurRadius: 40 + (20 * _pulseController.value),
                              spreadRadius: 5 + (10 * _pulseController.value),
                            ),
                          ],
                        ),
                        child: _buildPremiumLogo(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Staggered Text Animations
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Text(
                        "HUMAN SAFETY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 2,
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.accent,
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "PREMIUM PROTECTION ENGINE",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Glassmorphic Bottom Badges
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildGlassBadges(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLogo() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.5), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F3D),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.shield_rounded,
          size: 70,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGlassBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _glassBadge("SECURE", Icons.lock_outline),
        const SizedBox(width: 15),
        _glassBadge("LIVE", Icons.sensors),
        const SizedBox(width: 15),
        _glassBadge("TRUSTED", Icons.verified_user_outlined),
      ],
    );
  }

  Widget _glassBadge(String label, IconData icon) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Mesh Background Widget
class _AnimatedMeshBackground extends StatefulWidget {
  const _AnimatedMeshBackground();

  @override
  State<_AnimatedMeshBackground> createState() =>
      _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<_AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: MeshPainter(_controller.value),
        );
      },
    );
  }
}

class MeshPainter extends CustomPainter {
  final double progress;
  MeshPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Draw moving blobs of color
    final double x =
        size.width * (0.5 + 0.2 * math.sin(progress * 2 * math.pi));
    final double y =
        size.height * (0.3 + 0.1 * math.cos(progress * 2 * math.pi));

    canvas.drawCircle(
        Offset(x, y), 150, paint..color = AppColors.primary.withOpacity(0.2));
    canvas.drawCircle(
      Offset(size.width - x, size.height - y),
      200,
      paint..color = AppColors.accent.withOpacity(0.15),
    );
  }

  @override
  bool shouldRepaint(MeshPainter oldDelegate) => true;
}
