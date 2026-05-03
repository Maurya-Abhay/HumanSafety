import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../shared/models.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 200, child: _buildTopHeader()),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),

                      // Full Name Field (compact)
                      _buildInputField(
                        label: "Full Name",
                        controller: _nameController,
                        hint: "Full Name",
                        icon: Icons.person_outline_rounded,
                        suffixIcon: const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(height: 10),

                      // Email Field
                      _buildInputField(
                        label: "Email address",
                        controller: _emailController,
                        hint: "Email Address",
                        icon: Icons.mail_outline_rounded,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),

                      // Mobile Number Field
                      _buildInputField(
                        label: "Mobile number",
                        controller: _phoneController,
                        hint: "Mobile Number",
                        icon: Icons.phone_outlined,
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),

                      // Create Password Field
                      _buildInputField(
                        label: "Create a Password",
                        controller: _passwordController,
                        hint: "Enter a Password",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),
                      const SizedBox(height: 10),

                      // Confirm Password Field
                      _buildInputField(
                        label: "Confirm Password",
                        controller: _confirmPasswordController,
                        hint: "Retype Password",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),

                      const SizedBox(height: 12),

                      // Terms (compact)
                      Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Checkbox(
                              value: _acceptedTerms,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text('I accept Terms of Service & Privacy Policy', style: TextStyle(fontSize: 12, color: Colors.black87)))
                        ],
                      ),

                      const SizedBox(height: 14),
                      Consumer<AuthProvider>(builder: (context, auth, _) {
                        return SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _handleSignup(auth),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Get Set to Explore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }),

                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('Already a Member ? ', style: TextStyle(fontWeight: FontWeight.w600)), SizedBox(width: 6), Text('Login Now', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))]),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildTopHeader() {
    return Stack(
      children: [
        ClipPath(
          clipper: HeaderWaveClipper(),
          child: Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0000B2), // Deep Blue
                  Color(0xFF2563EB), // Bright Blue
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Register to Start Your Exciting\nLearning Process",
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    onPressed: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: type,
          style: const TextStyle(color: Colors.black87),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            if (isPassword && controller == _confirmPasswordController) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  // --- LOGIC METHOD (Unchanged structure) ---

  Future<void> _handleSignup(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if terms are accepted
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms of Service & Privacy Policy')),
      );
      return;
    }

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
      // Modern Error SnackBar logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
}

// Custom Clipper for the Top Blue Wave (Same as Login Screen)
class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}