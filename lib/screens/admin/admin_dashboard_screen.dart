import 'package:flutter/material.dart';
import 'package:iic_connect/screens/admin/batch_management_screen.dart';
import 'package:iic_connect/screens/admin/class_management_screen.dart';
import 'package:iic_connect/screens/admin/course_management_screen.dart';
import 'package:iic_connect/screens/admin/subject_management_screen.dart';
import 'package:iic_connect/screens/admin/user_management_screen.dart';
import 'package:iic_connect/utils/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildDashboardItem(
            context,
            icon: Icons.group,
            label: 'Manage Batches',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BatchManagementScreen(),
                ),
              );
            }
          ),
          _buildDashboardItem(
            context,
            icon: Icons.school,
            label: 'Manage Classes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassManagementScreen(),
                  ),
                );
              }
          ),
          _buildDashboardItem(
            context,
            icon: Icons.menu_book,
            label: 'Manage Courses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CourseManagementScreen(),
                  ),
                );
              }
          ),
          _buildDashboardItem(
            context,
            icon: Icons.subject,
            label: 'Manage Subjects',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubjectManagementScreen(),
                  ),
                );
              }
          ),
          _buildDashboardItem(
            context,
            icon: Icons.people,
            label: 'Manage Users',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                );
              }
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, ),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}