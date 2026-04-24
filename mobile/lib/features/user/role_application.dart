import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoleApplicationScreen extends StatefulWidget {
  const RoleApplicationScreen({Key? key}) : super(key: key);

  @override
  State<RoleApplicationScreen> createState() => _RoleApplicationScreenState();
}

class _RoleApplicationScreenState extends State<RoleApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedRole = 'police';
  String _selectedStaffType = 'paramedic';
  bool _isSubmitting = false;

  // Police specific
  final _badgeNumberController = TextEditingController();
  final _stationNameController = TextEditingController();
  final _stationAddressController = TextEditingController();

  // Hospital specific
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      _nameController.text = authProvider.user!.name;
      _phoneController.text = authProvider.user!.phone;
      _emailController.text = authProvider.user!.email;
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      final body = {
        'requestedRole': _selectedRole,
        'applicantName': _nameController.text,
        'applicantPhone': _phoneController.text,
        'applicantEmail': _emailController.text,
      };

      if (_selectedRole == 'police') {
        body.addAll({
          'badgeNumber': _badgeNumberController.text,
          'stationName': _stationNameController.text,
          'stationAddress': _stationAddressController.text,
        });
      } else {
        body.addAll({
          'hospitalName': _hospitalNameController.text,
          'hospitalAddress': _hospitalAddressController.text,
          'staffType': _selectedStaffType,
        });
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/user/role-application'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to submit';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Apply for Role',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Selection
              Text(
                'Select Role',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      'Police',
                      Icons.local_police_outlined,
                      'police',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      'Hospital',
                      Icons.local_hospital_outlined,
                      'hospital',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Personal Info
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Full Name',
                hint: 'Your full name',
                controller: _nameController,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone',
                hint: 'Your phone number',
                controller: _phoneController,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                hint: 'Your email address',
                controller: _emailController,
                readOnly: true,
              ),
              const SizedBox(height: 30),

              // Role-Specific Fields
              if (_selectedRole == 'police') ...[
                Text(
                  'Police Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Badge Number',
                  hint: 'Enter your badge number',
                  controller: _badgeNumberController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Badge number is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Station Name',
                  hint: 'Your police station name',
                  controller: _stationNameController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Station name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Station Address',
                  hint: 'Station address',
                  controller: _stationAddressController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Station address is required';
                    return null;
                  },
                  maxLines: 3,
                ),
              ] else ...[
                Text(
                  'Hospital Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Hospital Name',
                  hint: 'Name of your hospital',
                  controller: _hospitalNameController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Hospital name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Hospital Address',
                  hint: 'Hospital address',
                  controller: _hospitalAddressController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Hospital address is required';
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildStaffTypeDropdown(),
              ],
              const SizedBox(height: 30),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Process',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Admin will verify your information\n'
                      '• You will receive an email confirmation\n'
                      '• After approval, your role will be updated\n'
                      '• You can check status in your profile',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              PrimaryButton(
                label: _isSubmitting ? 'Submitting...' : 'Submit Application',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitApplication,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String label, IconData icon, String roleValue) {
    final isSelected = _selectedRole == roleValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = roleValue);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTypeDropdown() {
    const staffTypes = ['doctor', 'nurse', 'paramedic', 'admin', 'other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Staff Type',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedStaffType,
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStaffType = value);
              }
            },
            items: staffTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.capitalize()),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _badgeNumberController.dispose();
    _stationNameController.dispose();
    _stationAddressController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
