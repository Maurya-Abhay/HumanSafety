import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'accident';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _incidentTypes = [
    {'id': 'accident', 'label': 'Accident', 'icon': Icons.car_crash_rounded, 'color': Colors.orange},
    {'id': 'theft', 'label': 'Theft', 'icon': Icons.shopping_bag_rounded, 'color': Colors.blue},
    {'id': 'harassment', 'label': 'Harassment', 'icon': Icons.gpp_maybe_rounded, 'color': Colors.red},
    {'id': 'other', 'label': 'Other', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Submit Report', showBackButton: true),
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned(
            bottom: -50, left: -50,
            child: CircleAvatar(radius: 120, backgroundColor: AppColors.primary.withOpacity(0.03)),
          ),
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader(),
                const SizedBox(height: 24),

                // --- DYNAMIC TYPE SELECTOR ---
                const Text("What happened?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 16),
                _buildPremiumTypeSelector(),

                const SizedBox(height: 32),

                // --- DETAILS SECTION ---
                const Text("Incident Details", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 16),
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Brief Title',
                        hint: 'e.g., Collision at Crossroad',
                        controller: _titleController,
                        prefixIcon: Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Detailed Description',
                        hint: 'Describe the situation clearly...',
                        controller: _descriptionController,
                        maxLines: 5,
                        prefixIcon: Icons.segment_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- ATTACHMENTS & LOCATION ---
                const Text("Evidence & Location", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 16),
                _buildEvidenceSection(isDark),

                const SizedBox(height: 40),

                // --- SUBMIT BUTTON ---
                PrimaryButton(
                  label: 'SUBMIT OFFICIAL REPORT',
                  isLoading: _isLoading,
                  onPressed: _handleReportSubmission,
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "This is a legal document. Providing false info is punishable.",
                    style: TextStyle(fontSize: 10, color: AppColors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.gavel_rounded, color: AppColors.error, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your report will be sent directly to the nearest response unit.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPremiumTypeSelector() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _incidentTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = _incidentTypes[index];
          final isSelected = _selectedType == type['id'];
          final color = type['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedType = type['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'],
                    color: isSelected ? Colors.white : color,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEvidenceSection(bool isDark) {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.gps_fixed_rounded,
          title: "Automatic GPS Tagging",
          subtitle: "Current coordinates will be attached",
          trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success),
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.camera_enhance_rounded,
          title: "Attach Evidence",
          subtitle: "Upload photos or video clips",
          trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.grey),
          color: AppColors.primary,
          onTap: () {}, // Add Image Picker
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _handleReportSubmission() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all details'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null || token.isEmpty) {
        throw Exception('Login required to submit report');
      }

      await ApiService.createPanicAlert(
        token,
        latitude: position.latitude,
        longitude: position.longitude,
        description: '${_titleController.text.trim()}\n${_descriptionController.text.trim()}',
      );

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              const Text("Report Filed", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 8),
              const Text(
                "Your report has been successfully submitted. Responders have been alerted.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: "Understood",
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}