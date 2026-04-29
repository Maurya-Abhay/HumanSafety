import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart'; // Provider package ke liye
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

// YE WALA IMPORT JAROORI HAI (Path check kar lena apne project ke hisab se)
import '../../shared/models.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1411), // Warm premium charcoal
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
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
          // 1. Premium Background Gradients
          _buildBackgroundDesign(size),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeaderText(),
                      const SizedBox(height: 40),

                      // Glassmorphic Input Container
                      _buildSignupCard(),

                      const SizedBox(height: 30),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Create ID",
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your details to secure your account.",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(32),
            border:
                Border.all(color: const Color(0xFFF59E0B).withOpacity(0.16)),
          ),
          child: Column(
            children: [
              _buildRefinedField(
                controller: _nameController,
                hint: "Full Name",
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
              _buildRefinedField(
                controller: _emailController,
                hint: "Email Address",
                icon: Icons.alternate_email_rounded,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildRefinedField(
                controller: _phoneController,
                hint: "Mobile Number",
                icon: Icons.phone_android_rounded,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildRefinedField(
                controller: _passwordController,
                hint: "Create Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              _buildRefinedField(
                controller: _confirmPasswordController,
                hint: "Confirm Password",
                icon: Icons.verified_user_outlined,
                isPassword: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefinedField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.12)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Signup Button
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) => ElevatedButton(
              onPressed: () => _handleSignup(auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: auth.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("INITIALIZE ACCOUNT",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Already a member?",
                style: TextStyle(color: Colors.white.withOpacity(0.4))),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Sign In",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundDesign(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: _blurCircle(250, const Color(0xFF1D4ED8).withOpacity(0.2)),
        ),
        Positioned(
          bottom: size.height * 0.1,
          left: -100,
          child: _blurCircle(300, const Color(0xFF3B82F6).withOpacity(0.1)),
        ),
      ],
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Future<void> _handleSignup(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await auth.signup(
      _phoneController.text,
      _passwordController.text,
      _nameController.text,
      _emailController.text,
    );

    if (!mounted) return;
    if (ok) {
      String route = _homeRouteForRole(auth.user?.role ?? 'user');
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    } else {
      // Modern Error SnackBar logic yahan ayega
    }
  }

  String _homeRouteForRole(String role) {
    switch (role) {
      case 'police':
        return AppRoutes.policeDashboard;
      case 'hospital':
        return AppRoutes.hospitalDashboard;
      case 'admin':
        return AppRoutes.adminDashboard;
      default:
        return AppRoutes.userHome;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
