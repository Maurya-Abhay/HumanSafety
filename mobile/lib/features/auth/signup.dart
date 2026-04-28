import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text("Join HumanSafety community"),

                const SizedBox(height: 30),

                CustomTextField(
                  label: "Full Name",
                  hint: "Enter your full name",
                  controller: _nameController,
                  validator: (v) => v!.isEmpty ? "Name required" : null,
                ),

                const SizedBox(height: 12),

                CustomTextField(
                  label: "Email",
                  hint: "Enter your email",
                  controller: _emailController,
                  inputType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? "Email required" : null,
                ),

                const SizedBox(height: 12),

                CustomTextField(
                  label: "Phone",
                  hint: "Enter your phone number",
                  controller: _phoneController,
                  inputType: TextInputType.phone,
                  validator: (v) =>
                      v!.length < 10 ? "Valid phone required" : null,
                ),

                const SizedBox(height: 12),

                CustomTextField(
                  label: "Password",
                  hint: "Create a password (min 6 chars)",
                  controller: _passwordController,
                  isPassword: true,
                  validator: (v) =>
                      v!.length < 6 ? "Min 6 chars required" : null,
                ),

                const SizedBox(height: 12),

                CustomTextField(
                  label: "Confirm Password",
                  hint: "Re-enter your password",
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (v) =>
                      v != _passwordController.text ? "Not matched" : null,
                ),

                const SizedBox(height: 25),

                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return PrimaryButton(
                      label: "Sign Up",
                      isLoading: auth.isLoading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        final ok = await auth.signup(
                          _phoneController.text,
                          _passwordController.text,
                          _nameController.text,
                          _emailController.text,
                        );

                        if (!context.mounted) return;

                        if (ok) {
                          final homeRoute = _homeRouteForRole(auth.user?.role ?? 'user');
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            homeRoute,
                            (route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.error ?? 'Signup failed')),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _homeRouteForRole(String role) {
    switch (role) {
      case 'police':
        return AppRoutes.policeDashboard;
      case 'hospital':
        return AppRoutes.hospitalDashboard;
      case 'admin':
        return AppRoutes.adminDashboard;
      case 'user':
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
    super.dispose();
  }
}