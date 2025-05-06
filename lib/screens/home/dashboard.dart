import 'package:flutter/material.dart';
import 'package:iic_connect/models/user.dart';
import 'package:iic_connect/screens/notices/notices_screen.dart';
import 'package:iic_connect/screens/admin/create_notice_screen.dart';
import 'package:iic_connect/screens/attendance/attendance_screen.dart'; // Add this import
import 'package:iic_connect/utils/constants.dart';
import 'package:iic_connect/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Add this import

import '../../models/attendance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart'; // Add this import

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
              padding: const EdgeInsets.all(24),
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

            // Add Attendance Summary for Students
            if (user.role == AppConstants.studentRole)
              Consumer<AttendanceProvider>(
                builder: (context, attendanceProvider, child) {
                  if (attendanceProvider.attendanceSummaries.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final overallAttendance = _calculateOverallAttendance(
                    attendanceProvider.attendanceSummaries,
                  );

                  return Column(
                    children: [
                      const SizedBox(height: 24),

                      // Warning if attendance is low
                      if (overallAttendance < 75)
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your overall attendance is below 75%',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Attendance Chart Card
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AttendanceScreen(),
                            ),
                          );
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Your Attendance',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: SfCircularChart(
                                  series: <CircularSeries>[
                                    DoughnutSeries<double, String>(
                                      dataSource: [
                                        overallAttendance,
                                        100 - overallAttendance,
                                      ],
                                      xValueMapper: (_, index) =>
                                      index == 0 ? 'Present' : 'Absent',
                                      yValueMapper: (data, _) => data,
                                      pointColorMapper: (_, index) =>
                                      index == 0
                                          ? Theme.of(context).primaryColor
                                          : Colors.red,
                                      innerRadius: '70%',
                                      dataLabelSettings: const DataLabelSettings(
                                        isVisible: true,
                                      ),
                                    ),
                                  ],
                                  annotations: <CircularChartAnnotation>[
                                    CircularChartAnnotation(
                                      widget: Text(
                                        '${overallAttendance.toStringAsFixed(1)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayLarge
                                            ?.copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to view details',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
                      if (isAdmin || user.role == AppConstants.staffRole)
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
          ],
        ),
      ),
    );
  }

  // Widget _buildRoleSpecificDashboard(BuildContext context) {
  //   switch (user.role) {
  //     case AppConstants.studentRole:
  //       return _buildStudentDashboard(context);
  //     case AppConstants.facultyRole:
  //       return _buildFacultyDashboard(context);
  //     case AppConstants.staffRole:
  //       return _buildStaffDashboard(context);
  //     case AppConstants.adminRole:
  //       return _buildAdminDashboard(context);
  //     default:
  //       return const SizedBox.shrink();
  //   }
  // }

  // Helper function to calculate overall attendance percentage
  double _calculateOverallAttendance(List<AttendanceSummary> summaries) {
    if (summaries.isEmpty) return 0;
    final totalClasses = summaries.fold(
      0,
          (sum, item) => sum + item.totalClasses,
    );
    final attendedClasses = summaries.fold(
      0,
          (sum, item) => sum + item.attendedClasses,
    );
    return (attendedClasses / totalClasses) * 100;
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