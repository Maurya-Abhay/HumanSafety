import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/storage_service.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _specializationsController;
  late TextEditingController _bedsController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _specializationsController = TextEditingController(text: (user?.specializations ?? []).join(', '));
    _bedsController = TextEditingController(text: (user?.totalBeds ?? 0).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _specializationsController.dispose();
    _bedsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      final auth = context.read<AuthProvider>();
      final messenger = ScaffoldMessenger.of(context);

      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null || token.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Not authenticated. Please login again.')),
        );
        return;
      }

      // Call backend API
      final result = await ApiService.updateHospitalProfile(
        token,
        hospitalName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        specializations: _specializationsController.text.trim().isEmpty ? null : _specializationsController.text.split(',').map((s) => s.trim()).toList(),
        contactPerson: null,
      );

      if (!mounted) return;
      final currentUser = auth.user;
      if (currentUser != null && result.isNotEmpty) {
        final updated = currentUser.copyWith(
          hospitalName: result['name'],
          phone: result['phone'],
          address: result['address'],
          contactPerson: result['contactPerson'],
          totalBeds: result['totalBeds'] ?? currentUser.totalBeds,
          availableBeds: result['availableBeds'] ?? currentUser.availableBeds,
          specializations: result['specializations'] != null ? List<String>.from(result['specializations']) : currentUser.specializations,
        );
        auth.updateUser(updated);
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hospital Profile',
        showBackButton: true,
        actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHero(user),
                const SizedBox(height: 16),
                _buildProfileForm(),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    if (_isEditing) {
      return CustomCard(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Hospital Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.local_hospital_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specializationsController,
              decoration: InputDecoration(
                labelText: 'Specializations (comma separated)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.list_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bedsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Beds',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.bed_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => setState(() => _isEditing = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save',
                    onPressed: _saveProfile,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      final user = context.read<AuthProvider>().user;
      return Column(
        children: [
          _buildSectionTitle('Hospital Details'),
          const SizedBox(height: 10),
          _buildInfoItem('Hospital Name', user?.hospitalName ?? user?.name ?? '-'),
          _buildInfoItem('Email', user?.email ?? '-'),
          _buildInfoItem('Phone', user?.phone ?? '-'),
          _buildInfoItem('Beds', '${user?.availableBeds ?? 0}/${user?.totalBeds ?? 0}'),
          _buildInfoItem('Specializations', (user?.specializations ?? const []).isEmpty ? '-' : (user?.specializations ?? const []).join(', ')),
          _buildInfoItem('Verified', user?.isVerified ?? false ? 'Yes' : 'No'),
          _buildInfoItem('Joined', DateTime.now().toString().split(' ')[0]),
          const SizedBox(height: 20),
          _buildSectionTitle('Profile Actions'),
          const SizedBox(height: 10),
          PrimaryButton(label: 'Edit Profile', onPressed: () => setState(() => _isEditing = true)),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Sync Now', onPressed: _syncProfile),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Open Dashboard', onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.hospitalDashboard)),
        ],
      );
    }
  }

  Future<void> _syncProfile() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.fetchUserProfile();
      if (!mounted) return;
      if (success != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Profile synchronized')));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('No profile data returned')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    }
  }

  Widget _buildHero(User? user) {
    final displayName = user?.hospitalName?.isNotEmpty == true
      ? user!.hospitalName!
      : user?.name.isNotEmpty == true
        ? user!.name
        : 'Hospital Team';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(user?.email ?? 'hospital@domain.com', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Beds: ${user?.availableBeds ?? 0}/${user?.totalBeds ?? 0}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Text((user?.role ?? 'hospital').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Flexible(child: Text(value, textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }
}
