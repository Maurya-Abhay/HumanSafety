import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'HumanSafety',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.sos);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.contacts);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.profile);
        },
        items: [
          BottomNavItem(icon: Icons.home, label: 'Home'),
          BottomNavItem(icon: Icons.warning, label: 'SOS'),
          BottomNavItem(icon: Icons.people, label: 'Contacts'),
          BottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomCard(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tracking),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      const Text('Live Tracking', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomCard(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.report),
                  child: Column(
                    children: [
                      Icon(
                        Icons.report_outlined,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      const Text('Report', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomCard(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.roleApplication),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 32,
                        color: Colors.green,
                      ),
                      SizedBox(height: 8),
                      Text('Apply for Role', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomCard(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.contacts),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      const Text('Contacts', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Cases',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Consumer<CasesProvider>(
            builder: (context, casesProvider, _) {
              if (casesProvider.isLoading) {
                return const LoadingWidget();
              }
              if (casesProvider.cases.isEmpty) {
                return const Center(child: Text('No recent cases'));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: casesProvider.cases.length,
                itemBuilder: (context, index) {
                  final case_ = casesProvider.cases[index];
                  return CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                case_.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(case_.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                case_.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(case_.description),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                case_.location ?? 'Location unavailable',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.grey;
    }
  }
}
