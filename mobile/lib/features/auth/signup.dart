import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                const Text('Join HumanSafety community'),
                const SizedBox(height: 30),
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  inputType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Phone is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password is required';
                    if (value!.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Confirm password is required';
                    if (value != _passwordController.text) return 'Passwords don\'t match';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return PrimaryButton(
                      label: 'Sign Up',
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await authProvider.signup(
                            _phoneController.text,
                            _passwordController.text,
                            _nameController.text,
                          );
                          if (mounted && success) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.otp,
                              (route) => false,
                            );
                          }
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login'),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
