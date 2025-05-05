import 'package:flutter/material.dart';
import 'package:iic_connect/models/user.dart';
import 'package:iic_connect/screens/notices/notices_screen.dart';
import 'package:iic_connect/screens/admin/create_notice_screen.dart';
import 'package:iic_connect/utils/constants.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class Dashboard extends StatelessWidget {
  final User user;

  const Dashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.background,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${user.role.toUpperCase()} - ${user.department ?? AppConstants.departmentName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notices',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (isAdmin ||
                          user.role == AppConstants.staffRole)
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateNoticeScreen(),
                            ),
                          ),
                          tooltip: 'Create New Notice',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 400, // Fixed height for notices preview
                    child: NoticesScreen(showFullScreenButton: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // GlassCard(
            //   padding: const EdgeInsets.all(16),
            //   child: _buildRoleSpecificDashboard(context),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificDashboard(BuildContext context) {
    switch (user.role) {
      case AppConstants.studentRole:
        return _buildStudentDashboard(context);
      case AppConstants.facultyRole:
        return _buildFacultyDashboard(context);
      case AppConstants.staffRole:
        return _buildStaffDashboard(context);
      case AppConstants.adminRole:
        return _buildAdminDashboard(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStudentDashboard(BuildContext context) {
    return Column(
      children: [
        Text(
          'Student Dashboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        // Add student-specific widgets
      ],
    );
  }

  Widget _buildFacultyDashboard(BuildContext context) {
    return Column(
      children: [
        Text(
          'Faculty Dashboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        // Add faculty-specific widgets
      ],
    );
  }

  Widget _buildStaffDashboard(BuildContext context) {
    return Column(
      children: [
        Text(
          'Staff Dashboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        // Add staff-specific widgets
      ],
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    return Column(
      children: [
        Text(
          'Admin Dashboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        // Add admin-specific widgets
      ],
    );
  }
}