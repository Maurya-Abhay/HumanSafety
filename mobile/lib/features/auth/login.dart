import 'package:flutter/material.dart';
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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Logic ko same rakhne ke liye variable ka naam _phone hi rakha hai, 
  // bhale hi UI mein ab label "Email address" ho (ya dono mix kar sakte hain).
  final _phone = TextEditingController(); 
  final _password = TextEditingController();
  
  bool _rememberMe = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // compact header
                SizedBox(height: 160, child: _buildTopHeader()),

                // logo from assets (only on login)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/HumanSafetyLogo.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // form (compact, no scroll)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInputField(
                            label: "Phone number",
                            controller: _phone,
                            hint: "+91 98765 43210",
                            icon: Icons.phone_outlined,
                            type: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _buildInputField(
                            label: "Password",
                            controller: _password,
                            hint: "Password",
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: const Color(0xFF2563EB),
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Remember me', style: TextStyle(fontSize: 13)),
                              const Spacer(),
                              TextButton(onPressed: () {}, child: const Text('Forgot?', style: TextStyle(color: Color(0xFF2563EB))))
                            ],
                          ),

                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Row(children: [Expanded(child: Divider(color: Colors.grey.shade300)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: Colors.grey.shade500))), Expanded(child: Divider(color: Colors.grey.shade300))]),

                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Sign In with Google', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(width: 8), Text('G', style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold))]),
                            ),
                          ),

                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('New Here ?', style: TextStyle(fontWeight: FontWeight.w600)), SizedBox(width: 6), Text('Sign Up', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))]),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
            height: 220,
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Log In",
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Experience a better learning\nenvironment",
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
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
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
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

  // --- LOGIC METHOD (Unchanged as requested) ---

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final phone = _phone.text.trim();
    final password = _password.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter details')),
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

// Custom Clipper for the Top Blue Wave
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