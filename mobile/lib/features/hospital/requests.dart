import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/portal_sound_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late String _token;
  List<CaseItem> _requests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() => _isLoading = true);
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      if (_token.isNotEmpty) {
        final requests = await ApiService.getHospitalAlerts(_token);
        setState(() {
          _requests = requests;
          _error = null;
        });
        if (requests.isNotEmpty) {
          await PortalSoundService().playAlert();
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(String caseId) async {
    try {
      await ApiService.acceptEmergency(_token, caseId);
      await PortalSoundService().playNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency accepted')),
      );
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hospital Requests',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _requests.isEmpty
                    ? const Center(child: Text('No pending requests'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              child: ListTile(
                                leading: const Icon(Icons.emergency_share,
                                    color: AppColors.accent),
                                title: Text(
                                    request.description ?? 'Emergency Request'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Location: ${request.location}'),
                                    Text(request.createdAt
                                        .toString()
                                        .split('.')[0]),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _acceptRequest(request.id),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Requests tab
        onTap: (index) {
          if (index == 0)
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalDashboard);
          if (index == 1) return; // Current page
          if (index == 2)
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalAmbulance);
          if (index == 3)
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalSettings);
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}

class AmbulanceScreen extends StatelessWidget {
  const AmbulanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hospital Ambulance',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            child: ListTile(
              leading:
                  const Icon(Icons.directions_car, color: AppColors.success),
              title: Text('Ambulance ${index + 1}'),
              subtitle: const Text('Ready for deployment'),
              trailing: const Chip(label: Text('Available')),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Ambulance tab
        onTap: (index) {
          if (index == 0)
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalDashboard);
          if (index == 1)
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalRequests);
          if (index == 2) return; // Current page
          if (index == 3)
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalSettings);
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}

class HospitalCasesScreen extends StatelessWidget {
  const HospitalCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hospital Cases',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            child: ListTile(
              leading:
                  const Icon(Icons.medical_services, color: AppColors.info),
              title: Text('Patient Case ${index + 1}'),
              subtitle: const Text('Status: In Treatment'),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Cases are grouped under Requests
        onTap: (index) {
          if (index == 0)
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalDashboard);
          if (index == 1) return; // Current page
          if (index == 2)
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalAmbulance);
          if (index == 3)
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalSettings);
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Hospital Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: const Icon(Icons.local_hospital,
                  size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'City General Hospital',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Emergency Care Provider',
                style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 32),
            const CustomCard(
              child: ListTile(
                leading: Icon(Icons.location_on, color: AppColors.primary),
                title: Text('Address'),
                subtitle: Text('123 Hospital St, City'),
              ),
            ),
            const SizedBox(height: 12),
            const CustomCard(
              child: ListTile(
                leading: Icon(Icons.phone, color: AppColors.primary),
                title: Text('Phone'),
                subtitle: Text('+1 (555) 123-4567'),
              ),
            ),
            const SizedBox(height: 12),
            const CustomCard(
              child: ListTile(
                leading: Icon(Icons.email, color: AppColors.primary),
                title: Text('Email'),
                subtitle: Text('contact@hospital.com'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
