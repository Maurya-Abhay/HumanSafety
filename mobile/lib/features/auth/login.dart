import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  late AnimationController _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _bgAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1411), // Warm premium charcoal
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2B1B14),
                  Color(0xFF1A1411),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          // 1. Dynamic Background Elements
          _buildAnimatedBackground(size),

          // 2. Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Header Section
                    _buildHeader(),
                    const SizedBox(height: 40),

                    // Modern Glass Card
                    _buildGlassCard(context),

                    const SizedBox(height: 30),

                    // Social Logins (Pro touch)
                    _buildSocialLogins(),

                    const SizedBox(height: 40),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child:
              const Icon(Icons.shield_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          "HUMAN SAFETY",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Secure Access Portal",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(32),
            border:
                Border.all(color: const Color(0xFFF59E0B).withOpacity(0.16)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sign In",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),

                // Refined Input Fields
                _buildModernField(
                  controller: _phone,
                  hint: "Phone Number",
                  icon: Icons.phone_android_rounded,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                _buildModernField(
                  controller: _password,
                  hint: "Password",
                  icon: Icons.lock_open_rounded,
                  isPassword: true,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                          color: AppColors.primary.withOpacity(0.8),
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Premium Gradient Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _handleLogin(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "Authenticate",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.12)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$hint is required';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
          prefixIcon:
              Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSocialLogins() {
    return Column(
      children: [
        Text("OR CONTINUE WITH",
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                letterSpacing: 1.5)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(Icons.g_mobiledata_rounded),
            const SizedBox(width: 20),
            _socialIcon(Icons.apple_rounded),
          ],
        )
      ],
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("No account?",
            style: TextStyle(color: Colors.white.withOpacity(0.4))),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
          child: const Text("Create ID",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: size.height * 0.1,
              left: size.width * (0.1 + (0.05 * _bgAnimation.value)),
              child:
                  _blurCircle(150, const Color(0xFFF59E0B).withOpacity(0.16)),
            ),
            Positioned(
              bottom: size.height * 0.2,
              right: size.width * (0.1 + (0.05 * _bgAnimation.value)),
              child:
                  _blurCircle(200, const Color(0xFFF97316).withOpacity(0.12)),
            ),
          ],
        );
      },
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final phone = _phone.text.trim();
    final password = _password.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone and password')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await authProvider.login(phone, password);
    if (mounted) Navigator.pop(context);

    if (success) {
      if (mounted) {
        final role = authProvider.user?.role ?? 'user';
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.getHomeRouteForRole(role),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Login failed')),
        );
      }
    }
  }
}
