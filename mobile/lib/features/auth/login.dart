import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
                const SizedBox(height: 40),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                const Text('Login to your HumanSafety account'),
                const SizedBox(height: 40),
                CustomTextField(
                  label: 'Phone',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  inputType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Phone is required';
                    if (value!.length < 10) return 'Invalid phone';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password is required';
                    if (value!.length < 6) return 'Password too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.otp),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 30),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return PrimaryButton(
                      label: 'Login',
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await authProvider.login(
                            _phoneController.text,
                            _passwordController.text,
                          );
                          if (mounted && success) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.splash,
                              (route) => false,
                            );
                          }
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
