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
    _nameController = TextEditingController(text: user?.hospitalName ?? user?.name ?? '');
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

      final result = await ApiService.updateHospitalProfile(
        token,
        hospitalName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        specializations: _specializationsController.text.trim().isEmpty 
            ? null 
            : _specializationsController.text.split(',').map((s) => s.trim()).toList(),
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
          specializations: result['specializations'] != null 
              ? List<String>.from(result['specializations']) 
              : currentUser.specializations,
        );
        auth.updateUser(updated);
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra-clean soft grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Hospital Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 28),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHero(user),
                const SizedBox(height: 24),
                _buildProfileForm(),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Update Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 18),
            _buildInputField(
              controller: _nameController,
              label: 'Hospital Name',
              icon: Icons.local_hospital_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_rounded,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _phoneController,
              label: 'Contact Number',
              icon: Icons.phone_rounded,
              type: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _addressController,
              label: 'Full Address',
              icon: Icons.location_on_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _specializationsController,
              label: 'Specializations (comma separated)',
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _bedsController,
              label: 'Total Available Beds',
              icon: Icons.bed_rounded,
              type: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('General Information'),
          const SizedBox(height: 12),
          _buildDetailItem(Icons.local_hospital_rounded, 'Hospital Name', user?.hospitalName ?? user?.name ?? '-'),
          _buildDetailItem(Icons.email_rounded, 'Email', user?.email ?? '-'),
          _buildDetailItem(Icons.phone_rounded, 'Phone', user?.phone ?? '-'),
          _buildDetailItem(Icons.bed_rounded, 'Total Beds Capacity', '${user?.availableBeds ?? 0} / ${user?.totalBeds ?? 0}'),
          _buildDetailItem(Icons.star_rounded, 'Specializations', (user?.specializations ?? const []).isEmpty ? '-' : (user?.specializations ?? const []).join(', ')),
          _buildDetailItem(Icons.verified_user_rounded, 'Status Verified', user?.isVerified ?? false ? 'Verified Hospital' : 'Unverified'),
          _buildDetailItem(Icons.calendar_month_rounded, 'Profile Created', DateTime.now().toString().split(' ')[0]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('System Actions'),
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text("Edit Profile Information", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _syncProfile,
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text("Refresh Profile Data", style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.hospitalDashboard),
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: const Text("Switch to Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
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
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile synchronized'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('No profile data returned'), backgroundColor: Colors.orangeAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.redAccent),
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                )
              ]
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Colors.white.withOpacity(0.18),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H', 
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'hospital@domain.com', 
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), 
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, color: Colors.white, size: 13),
                const SizedBox(width: 6),
                Text(
                  (user?.role ?? 'Hospital').toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title, 
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w800, 
          color: Color(0xFF0F172A),
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 3),
                Text(
                  value, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}