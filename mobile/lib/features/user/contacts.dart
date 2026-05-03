import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart' show AuthProvider;
import '../../core/api_service.dart';
import '../../core/routes.dart';
import '../../core/page_transitions.dart';
import '../../core/theme.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import './home.dart';
import './sos.dart';
import '../settings/settings.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> contacts = [];
  bool isLoading = true;
  String? error;
  
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final relationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // ... (Logic functions like _loadContacts, _addContact, _deleteContact stay same)

  void _showAddContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Emergency Contact",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "This person will be notified during an SOS alert.",
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Full Name',
              hint: 'e.g. John Doe',
              controller: nameController,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone Number',
              hint: '+91 XXXXX XXXXX',
              controller: phoneController,
              inputType: TextInputType.phone,
              prefixIcon: Icons.phone_android_rounded,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Relationship',
              hint: 'e.g. Brother, Friend',
              controller: relationController,
              prefixIcon: Icons.family_restroom_rounded,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Save Contact',
              onPressed: _addContact,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Safety Circle',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContactSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: LoadingWidget())
          : error != null
              ? _buildErrorState()
              : contacts.isEmpty
                  ? _buildEmptyState()
                  : _buildContactList(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) PageTransitions.replaceSmooth(context, const UserHomeScreen());
          if (index == 1) PageTransitions.replaceSmooth(context, const SOSScreen());
          if (index == 3) PageTransitions.replaceSmooth(context, const SettingsScreen());
        },
        items: [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.warning_amber_rounded, label: 'SOS'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    final userName = context.watch<AuthProvider>().user?.name.trim();
    final displayName = (userName == null || userName.isEmpty) ? 'User' : userName;

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: contacts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF2FF), Color(0xFFF5F9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      displayName.characters.first.toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Safety Circle', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('$displayName, you have ${contacts.length} trusted contacts', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final contact = contacts[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    contact.name.isNotEmpty ? contact.name.characters.first.toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(contact.relation, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(contact.phone, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Call Contact',
                      icon: const Icon(Icons.call_rounded, color: AppColors.success, size: 20),
                      onPressed: () async {
                        final uri = Uri.parse('tel:${contact.phone}');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete Contact',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      onPressed: () => _confirmDeleteContact(contact),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: AppColors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text("Your circle is empty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Add trusted contacts for emergency alerts", style: TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
          const SizedBox(height: 16),
          Text("Something went wrong", style: TextStyle(color: AppColors.grey)),
          TextButton(onPressed: _loadContacts, child: const Text("Try Again")),
        ],
      ),
    );
  }

  // Logic methods
  Future<void> _loadContacts() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null) {
        final response = await ApiService.getContacts(token);
        if (mounted) {
          setState(() => contacts = response);
        }
      } else {
        contacts = [];
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _addContact() async {
    try {
      if (nameController.text.isEmpty || phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null) {
        await ApiService.addContact(
          token,
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          relation: relationController.text.trim().isEmpty ? 'Friend' : relationController.text.trim(),
        );
      }
      nameController.clear();
      phoneController.clear();
      relationController.clear();
      if (mounted) {
        Navigator.pop(context);
      }
      await _loadContacts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteContact(String contactId) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null) {
        await ApiService.deleteContact(token, contactId);
      }
      await _loadContacts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting contact: $e')),
      );
    }
  }

  Future<void> _confirmDeleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete contact?'),
        content: Text('Are you sure you want to remove ${contact.name} from your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteContact(contact.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${contact.name} deleted'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}