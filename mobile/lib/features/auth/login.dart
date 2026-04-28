import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                Text("Welcome Back",
                    style: Theme.of(context).textTheme.headlineLarge),

                const SizedBox(height: 30),

                CustomTextField(
                  label: "Phone",
                  hint: "Enter your phone number",
                  controller: _phone,
                  inputType: TextInputType.phone,
                ),

                const SizedBox(height: 12),

                CustomTextField(
                  label: "Password",
                  hint: "Enter your password",
                  controller: _password,
                  isPassword: true,
                ),

                const SizedBox(height: 25),

                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return PrimaryButton(
                      label: "Login",
                      isLoading: auth.isLoading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        final ok = await auth.login(
                          _phone.text,
                          _password.text,
                        );

                        if (!context.mounted) return;

                        if (ok) {
                          final homeRoute = _homeRouteForRole(auth.user?.role ?? 'user');
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            homeRoute,
                            (r) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.error ?? 'Login failed')),
                          );
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account? '),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                      child: const Text('Sign Up'),
                    ),
                  ],
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
}