import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({Key? key}) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'OTP Verification'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Verify Your Account',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Enter your phone number and OTP code'),
            const SizedBox(height: 30),
            if (!_otpSent) ...[
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: _phoneController,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return PrimaryButton(
                    label: _isLoading ? 'Sending OTP...' : 'Send OTP',
                    isLoading: _isLoading,
                    onPressed: () async {
                      if (_phoneController.text.length >= 10) {
                        setState(() => _isLoading = true);
                        final success = await authProvider.sendOtp(_phoneController.text);
                        setState(() {
                          _isLoading = false;
                          if (success) _otpSent = true;
                        });
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to send OTP')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ] else ...[
              Text('OTP sent to ${_phoneController.text}'),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'OTP Code',
                hint: 'Enter 4-digit code',
                controller: _otpController,
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return PrimaryButton(
                    label: _isLoading ? 'Verifying...' : 'Verify & Login',
                    isLoading: _isLoading,
                    onPressed: () async {
                      if (_otpController.text.length >= 4) {
                        setState(() => _isLoading = true);
                        final success = await authProvider.verifyOtp(
                          _phoneController.text,
                          _otpController.text,
                        );
                        setState(() => _isLoading = false);
                        if (mounted && success) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.splash,
                            (route) => false,
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid OTP')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _otpSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text('Change Phone Number'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
