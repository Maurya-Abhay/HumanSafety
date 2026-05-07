import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Info Controllers
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  late TextEditingController bloodGroupController;
  late TextEditingController medicalConditionsController;
  late TextEditingController emergencyContactController;
  late TextEditingController emergencyContactNameController;
  late TextEditingController occupationController;
  late TextEditingController aboutController;

  // Additional Profile Controllers
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController zipCodeController;
  late TextEditingController aadharController;

  bool isEditing = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    genderController = TextEditingController();
    dobController = TextEditingController();
    bloodGroupController = TextEditingController();
    medicalConditionsController = TextEditingController();
    emergencyContactController = TextEditingController();
    emergencyContactNameController = TextEditingController();
    occupationController = TextEditingController();
    aboutController = TextEditingController();
    
    cityController = TextEditingController();
    stateController = TextEditingController();
    zipCodeController = TextEditingController();
    aadharController = TextEditingController();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isSaving = true);
      final authProvider = context.read<AuthProvider>();
      final token = await StorageService.getString(AppConstants.tokenKey);

      if (token != null) {
        await ApiService.updateProfile(token, {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'bloodType': bloodGroupController.text.trim(),
          'allergies': medicalConditionsController.text.trim(),
          'dateOfBirth': dobController.text.trim(),
          'gender': genderController.text.trim(),
          'aadharNumber': aadharController.text.trim(),
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'zipCode': zipCodeController.text.trim(),
          'medicalHistory': medicalConditionsController.text.trim(),
          'emergencyContactName': emergencyContactNameController.text.trim(),
          'emergencyContactPhone': emergencyContactController.text.trim(),
        });

        await authProvider.fetchUserProfile();

        if (!mounted) return;

        setState(() {
          isEditing = false;
          isSaving = false;
        });

        _showSnackBar('Profile updated successfully', AppColors.success);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      _showSnackBar('Update failed: $e', AppColors.error);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Ultra light grey/blue background
      appBar: CustomAppBar(
        title: 'My Profile',
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: LoadingWidget(message: "Fetching details..."));
          }

          // Sync controllers only when starting edit
          if (isEditing && nameController.text.isEmpty) {
            nameController.text = user.name;
            emailController.text = user.email;
            addressController.text = user.address ?? '';
            genderController.text = user.gender ?? '';
            dobController.text = user.dateOfBirth ?? '';
            bloodGroupController.text = user.bloodGroup ?? '';
            medicalConditionsController.text = user.medicalConditions ?? '';
            emergencyContactController.text = user.emergencyContact ?? '';
            emergencyContactNameController.text = user.emergencyContactName ?? '';
            occupationController.text = user.occupation ?? '';
            aboutController.text = user.about ?? '';
            
            // Note: If your User model supports these fields, map them here like above:
            // cityController.text = user.city ?? '';
            // stateController.text = user.state ?? '';
            // zipCodeController.text = user.zipCode ?? '';
            // aadharController.text = user.aadharNumber ?? '';
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatarSection(user),
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isEditing ? _buildEditFields() : _buildInfoView(user),
                  ),
                  const SizedBox(height: 30),
                  _buildActionButtons(authProvider),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.userHome);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.sos);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.contacts);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.settings);
        },
        items: const [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.warning_amber_rounded, label: 'SOS'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(User user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 5)
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', // Fixed RangeError
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {}, // Add Image Pick Logic
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(blurRadius: 5, color: Colors.black12)
                    ]),
                child: const Icon(Icons.edit_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
            user.role.toUpperCase(),
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoView(User user) {
    final profileCompletion = user.profileCompletion;
    final canApplyForRole = user.isProfileComplete;
    
    return Column(
      children: [
        // Profile Completion Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Completion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    '$profileCompletion%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: profileCompletion == 100 ? Colors.green : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: profileCompletion / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    profileCompletion == 100 ? Colors.green : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (profileCompletion < 100)
                Text(
                  'Complete your profile to apply for official roles',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey.withOpacity(0.7),
                  ),
                )
              else
                const Text(
                  '✓ Profile complete! You can now apply for official roles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (canApplyForRole) ...[
          PrimaryButton(
            label: 'Apply for Official Role',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.roleApplication),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'View Application Status',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.applicationStatus),
          ),
          const SizedBox(height: 24),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: const Text(
              'Complete every profile field before applying for an official role.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        _buildSectionHeader("Personal Information"),
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTile(Icons.email_outlined, "Email Address", user.email),
              _buildDivider(),
              _buildListTile(Icons.phone_android_rounded, "Phone Number", user.phone),
              _buildDivider(),
              _buildListTile(Icons.location_on_outlined, "Address", user.address ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.person_pin_circle_outlined, "Gender", user.gender ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.cake_outlined, "Date of Birth", user.dateOfBirth ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.bloodtype_outlined, "Blood Group", user.bloodGroup ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.medical_services_outlined, "Medical Conditions", user.medicalConditions ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.contact_emergency_outlined, "Emergency Contact", user.emergencyContact ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.person_add_alt_1_outlined, "Emergency Contact Name", user.emergencyContactName ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.work_outline, "Occupation", user.occupation ?? '-'),
              _buildDivider(),
              _buildListTile(Icons.info_outline, "About", user.about ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Safety Statistics"),
        Row(
          children: [
            Expanded(child: _buildStatCard("SOS Sent", "12", Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Score", "98%", Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildEditFields() {
    return Column(
      children: [
        CustomCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Basic Information",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Full Name",
                hint: "Enter your full name",
                controller: nameController,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v!.isEmpty ? "Name can't be empty" : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: "Email Address",
                hint: "Enter your email address",
                controller: emailController,
                prefixIcon: Icons.alternate_email_rounded,
                inputType: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? "Enter a valid email" : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: "Address",
                hint: "Enter your address",
                controller: addressController,
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Gender",
                      hint: "Gender",
                      controller: genderController,
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Date of Birth",
                      hint: "DD/MM/YYYY",
                      controller: dobController,
                      prefixIcon: Icons.cake_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Blood Group",
                      hint: "Blood group",
                      controller: bloodGroupController,
                      prefixIcon: Icons.bloodtype_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Occupation",
                      hint: "Your occupation",
                      controller: occupationController,
                      prefixIcon: Icons.work_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: "Medical Conditions",
                hint: "Health or allergy notes",
                controller: medicalConditionsController,
                prefixIcon: Icons.medical_services_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: "Emergency Contact Name",
                hint: "Contact person name",
                controller: emergencyContactNameController,
                prefixIcon: Icons.person_add_alt_1_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: "Emergency Contact Phone",
                hint: "Contact number",
                controller: emergencyContactController,
                prefixIcon: Icons.phone,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: "About",
                hint: "Short profile bio",
                controller: aboutController,
                prefixIcon: Icons.info_outline,
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Complete Your Profile",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text("Fill all details to apply for official roles",
                  style: TextStyle(fontSize: 12, color: AppColors.grey)),
              const SizedBox(height: 16),
              // Removed duplicated fields (DOB, Address, Emergency Contacts) and attached proper controllers
              CustomTextField(
                label: "Aadhar Number",
                hint: "Enter your Aadhar number",
                controller: aadharController,
                prefixIcon: Icons.badge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "City",
                      hint: "City",
                      controller: cityController,
                      prefixIcon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "State",
                      hint: "State",
                      controller: stateController,
                      prefixIcon: Icons.map,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: "Zip Code",
                hint: "Postal code",
                controller: zipCodeController,
                prefixIcon: Icons.markunread_mailbox,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 22),
      title: Text(title,
          style: const TextStyle(
              fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, indent: 55, color: Colors.grey.shade200);

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    return isEditing
        ? Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Discard',
                  onPressed: () => setState(() => isEditing = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Save Changes',
                  isLoading: isSaving,
                  onPressed: _updateProfile,
                ),
              ),
            ],
          )
        : Column(
            children: [
              PrimaryButton(
                label: 'Edit Profile',
                onPressed: () => setState(() => isEditing = true),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _handleLogout(authProvider),
                child: const Text("Logout Account",
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          );
  }

  void _handleLogout(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout?"),
        content: const Text("Are you sure you want to end your session?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    genderController.dispose();
    dobController.dispose();
    bloodGroupController.dispose();
    medicalConditionsController.dispose();
    emergencyContactController.dispose();
    emergencyContactNameController.dispose();
    occupationController.dispose();
    aboutController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    aadharController.dispose();
    super.dispose();
  }
}