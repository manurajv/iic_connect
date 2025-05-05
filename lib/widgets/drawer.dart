import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iic_connect/screens/admin/admin_dashboard_screen.dart';
import 'package:iic_connect/screens/attendance/attendance_screen.dart';
import 'package:iic_connect/screens/attendance/mark_attendance.dart';
import 'package:iic_connect/screens/labs/labs_screen.dart';
import 'package:iic_connect/screens/projects/projects_screen.dart';
import 'package:iic_connect/screens/timetable/add_timetable_screen.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/screens/timetable/timetable_screen.dart';
import 'package:iic_connect/screens/admin/user_management_screen.dart';
import 'package:iic_connect/screens/admin/system_settings_screen.dart';
import 'package:iic_connect/screens/admin/analytics_screen.dart';
import 'package:iic_connect/utils/constants.dart';

import '../models/user.dart';
import '../providers/subject_provider.dart';
import '../screens/admin/enrollment_approval_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/enrollment/enrollment_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2)
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.4),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context, user),
                  Expanded(child: _buildMenuItems(context, authProvider)),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: Text(
            user?.name.isNotEmpty == true ? user!.name[0] : 'G',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        title: Text(
          user?.name ?? 'Guest',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user?.email ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    final isAdmin = authProvider.isAdmin;

    return SingleChildScrollView(
      child: Column(
        children: [
          _DrawerTile(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_filled,
            title: 'Home',
            onTap: () => _navigateTo(context, '/home'),
          ),

          if (isAdmin) ...[
            if (user != null &&
                (isAdmin || user.role == AppConstants.staffRole))
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Admin Management'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
            _DrawerTile(
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics,
              title: 'Analytics Dashboard',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsScreen()),
              ),
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              title: 'System Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SystemSettingsScreen()),
              ),
            ),
            _DrawerTile(
              icon: Icons.approval_outlined,
              activeIcon: Icons.approval,
              title: 'Enrollment Approval',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const EnrollmentApprovalScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
          ],

          if (isAdmin || user?.role == AppConstants.studentRole || user?.role == AppConstants.facultyRole) ...[
            _DrawerTile(
              icon: Icons.schedule_outlined,
              activeIcon: Icons.schedule,
              title: 'Timetable',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TimetableScreen()),
              ),
            ),
            _DrawerTile(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment,
              title: 'Attendance',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AttendanceScreen()),
              ),
            ),
          ],

          if (isAdmin || user?.role == AppConstants.facultyRole) ...[
            _DrawerTile(
              icon: Icons.supervisor_account_outlined,
              activeIcon: Icons.supervisor_account,
              title: 'Project Supervision',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProjectsScreen()),
              ),
            ),
            _DrawerTile(
              icon: Icons.computer_outlined,
              activeIcon: Icons.computer,
              title: 'Lab Management',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LabsScreen()),
              ),
            ),
            _DrawerTile(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              title: 'Timetable Management',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTimetableScreen()),
              ),
            ),
            // _DrawerTile(
            //   icon: Icons.bookmark_add,
            //   activeIcon: Icons.bookmark_added,
            //   title: 'Attendance Management',
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => MarkAttendanceScreen(subjectId: subjectId, subjectName: subjectName, students: students)),
            //   ),
            // ),
          ],

          if (isAdmin || user?.role == AppConstants.studentRole) ...[
            _DrawerTile(
              icon: Icons.school_outlined,
              activeIcon: Icons.school,
              title: 'Enrollment',
              onTap: () {
                // Ensure SubjectProvider is loaded
                Provider.of<SubjectProvider>(context, listen: false).loadAllSubjects();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EnrollmentScreen()),
                );
              },
            ),
          ],
          if (user != null &&
              (isAdmin || user.role == AppConstants.staffRole))
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Register User'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),
        _DrawerTile(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          title: 'Settings',
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => SettingsScreen()),
            // );
          },
        ),
        _DrawerTile(
          icon: Icons.logout_outlined,
          title: 'Logout',
          onTap: () {
            context.read<AuthProvider>().logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    this.activeIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = ModalRoute.of(context)?.settings.name?.contains(
        title.toLowerCase().replaceAll(' ', '')) ?? false;

    return ListTile(
      leading: Icon(
        isActive ? activeIcon ?? icon : icon,
        color: isActive
            ? Theme.of(context).primaryColor
            : Theme.of(context).iconTheme.color?.withOpacity(0.8),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isActive
              ? Theme.of(context).primaryColor
              : null,
        ),
      ),
      onTap: onTap,
    );
  }
}