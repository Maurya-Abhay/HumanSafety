import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoleApplicationScreen extends StatefulWidget {
  const RoleApplicationScreen({super.key});

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

  final _badgeNumberController = TextEditingController();
  final _stationNameController = TextEditingController();
  final _stationAddressController = TextEditingController();
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

  // Same logic as before, just kept it clean
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
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

      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final error = jsonDecode(response.body)['message'] ??
            'Failed to submit application.';
        _showErrorSnackBar(error);
      }
    } catch (e) {
      _showErrorSnackBar('Connection Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
          title: 'Authority Verification', showBackButton: true),
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
                radius: 100,
                backgroundColor: AppColors.primary.withOpacity(0.05)),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),

                  // --- ROLE SELECTION TILES ---
                  const Text('Select Your Department',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildRoleCard(
                              'Police Force', Icons.shield_rounded, 'police')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildRoleCard('Medical Staff',
                              Icons.health_and_safety_rounded, 'hospital')),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- FORM SECTIONS ---
                  _buildSectionTitle('Personal Credentials'),
                  _buildPersonalFields(isDark),

                  const SizedBox(height: 24),

                  _buildSectionTitle(_selectedRole == 'police'
                      ? 'Department Details'
                      : 'Facility Details'),

                  // Animated Switcher for Dynamic Fields
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      key: ValueKey(_selectedRole),
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _selectedRole == 'police'
                              ? _buildPoliceFields()
                              : _buildHospitalFields(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildVerificationInfoBox(),
                  const SizedBox(height: 40),

                  PrimaryButton(
                    label: 'Submit Official Request',
                    isLoading: _isSubmitting,
                    onPressed: _submitApplication,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Official roles grant access to emergency response tools. Verification may take 24-48 hours.",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildPersonalFields(bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReadOnlyField(
              'Full Name', _nameController, Icons.person_rounded),
          const SizedBox(height: 12),
          _buildReadOnlyField(
              'Phone Number', _phoneController, Icons.phone_android_rounded),
          const SizedBox(height: 12),
          _buildReadOnlyField('Official Email', _emailController,
              Icons.alternate_email_rounded),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(
      String label, TextEditingController ctrl, IconData icon) {
    return CustomTextField(
      label: label,
      hint: label,
      controller: ctrl,
      readOnly: true,
      prefixIcon: icon,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
    );
  }

  Widget _buildRoleCard(String label, IconData icon, String roleValue) {
    final isSelected = _selectedRole == roleValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = roleValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.greyLight.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 48, color: isSelected ? Colors.white : AppColors.grey),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPoliceFields() {
    return [
      CustomTextField(
        label: 'Badge Number',
        hint: 'UID-XXXX-XXXX',
        controller: _badgeNumberController,
        prefixIcon: Icons.badge_rounded,
        validator: (value) => value!.isEmpty ? 'Badge ID is required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Assigned Station',
        hint: 'Headquarters / Local Unit',
        controller: _stationNameController,
        prefixIcon: Icons.account_balance_rounded,
        validator: (value) =>
            value!.isEmpty ? 'Station name is required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Station Address',
        hint: 'Street, City, State',
        controller: _stationAddressController,
        prefixIcon: Icons.map_outlined,
        maxLines: 2,
        validator: (value) => value!.isEmpty ? 'Address is required' : null,
      ),
    ];
  }

  List<Widget> _buildHospitalFields() {
    return [
      CustomTextField(
        label: 'Hospital Name',
        hint: 'Full Medical Center Name',
        controller: _hospitalNameController,
        prefixIcon: Icons.local_hospital_rounded,
        validator: (value) =>
            value!.isEmpty ? 'Hospital name is required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Facility Address',
        hint: 'Official location',
        controller: _hospitalAddressController,
        prefixIcon: Icons.location_on_rounded,
        maxLines: 2,
        validator: (value) => value!.isEmpty ? 'Address is required' : null,
      ),
      const SizedBox(height: 16),
      _buildStaffTypeDropdown(),
    ];
  }

  Widget _buildStaffTypeDropdown() {
    const staffTypes = ['doctor', 'nurse', 'paramedic', 'admin', 'other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('  Designation',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.greyLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStaffType,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              icon:
                  const Icon(Icons.unfold_more_rounded, color: AppColors.grey),
              onChanged: (value) => setState(() => _selectedStaffType = value!),
              items: staffTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toTitleCase(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationInfoBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Verification Policy',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'By submitting, you agree that your data will be cross-checked with official databases. Impersonation of a public servant is a legal offense.',
                style: TextStyle(fontSize: 12, height: 1.5),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.success,
                child: Icon(Icons.check_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text("Request Received",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 12),
              const Text(
                "We are validating your credentials. You will be notified once your role is active.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: "Got it",
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                ),
              )
            ],
          ),
        ),
      ),
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

extension StringFormatting on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
