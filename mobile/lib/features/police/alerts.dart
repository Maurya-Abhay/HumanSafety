import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late String _token;
  List<CaseItem> _cases = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() => _isLoading = true);
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      if (_token.isNotEmpty) {
        final cases = await ApiService.getPoliceAlerts(_token);
        setState(() {
          _cases = cases;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptCase(String caseId) async {
    try {
      await ApiService.acceptEmergency(_token, caseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Case accepted successfully')),
      );
      _loadAlerts();
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
      appBar: const CustomAppBar(title: 'Alerts'),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _cases.isEmpty
                    ? const Center(child: Text('No active alerts'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cases.length,
                        itemBuilder: (context, index) {
                          final caseItem = _cases[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              child: ListTile(
                                leading: const Icon(Icons.warning, color: AppColors.warning),
                                title: Text(caseItem.description ?? 'Emergency Alert'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Location: ${caseItem.location?['address'] ?? 'Unknown'}'),
                                    Text('Status: ${caseItem.status}'),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _acceptCase(caseItem.id),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  late String _token;
  List<CaseItem> _cases = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      setState(() => _isLoading = true);
      _token = await StorageService.getString(AppConstants.tokenKey) ?? '';
      if (_token.isNotEmpty) {
        final cases = await ApiService.getPoliceAlerts(_token);
        setState(() {
          _cases = cases;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String caseId, String status) async {
    try {
      await ApiService.updateCaseStatus(_token, caseId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
      _loadCases();
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
      appBar: const CustomAppBar(title: 'Cases'),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _cases.isEmpty
                    ? const Center(child: Text('No cases assigned'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cases.length,
                        itemBuilder: (context, index) {
                          final caseItem = _cases[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              child: ListTile(
                                leading: const Icon(Icons.description, color: AppColors.primary),
                                title: Text(caseItem.description ?? 'Case'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Location: ${caseItem.location?['address'] ?? 'Unknown'}'),
                                    Text('Status: ${caseItem.status}'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    _updateStatus(caseItem.id, value);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'in-progress',
                                      child: Text('In Progress'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'resolved',
                                      child: Text('Resolved'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'closed',
                                      child: Text('Closed'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class PatrolScreen extends StatelessWidget {
  const PatrolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Patrol'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: AppColors.grey),
                    SizedBox(height: 12),
                    Text('Live Patrol Map'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Officers on Duty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: const Text('Officer John'),
                subtitle: const Text('Zone A - Active'),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: const Text('Officer Sarah'),
                subtitle: const Text('Zone B - Active'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Police Profile'),
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
              child: const Icon(Icons.local_police, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Police Department',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Public Safety Unit', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 32),
            const CustomCard(
              child: ListTile(
                leading: Icon(Icons.location_on, color: AppColors.primary),
                title: Text('Station'),
                subtitle: Text('Central Police Station'),
              ),
            ),
            const SizedBox(height: 12),
            const CustomCard(
              child: ListTile(
                leading: Icon(Icons.phone, color: AppColors.primary),
                title: Text('Emergency Line'),
                subtitle: Text('+1 (555) 911-0000'),
              ),
            ),
            const SizedBox(height: 12),
            const CustomCard(
              child: ListTile(
                leading: Icon(Icons.email, color: AppColors.primary),
                title: Text('Email'),
                subtitle: Text('police@department.gov'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
