import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:iic_connect/providers/attendance_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';

import '../../models/attendance.dart';
import '../../widgets/attendance_card.dart';
import 'mark_attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedSubjectId;
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final attendanceProvider = context.read<AttendanceProvider>();

      if (authProvider.user != null) {
        if (authProvider.user!.role == 'student') {
          await attendanceProvider.loadStudentAttendance(authProvider.user!.id);
        } else if (_selectedSubjectId != null) {
          await attendanceProvider.loadSubjectAttendance(_selectedSubjectId!);
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
      // Optionally show error to user
    } finally {
      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    if (!_initialLoadComplete) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          if (authProvider.user?.role != 'student')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToMarkAttendance(context),
            ),
        ],
      ),
      body: _buildBody(context, authProvider, attendanceProvider),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider, AttendanceProvider attendanceProvider) {
    if (attendanceProvider.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (attendanceProvider.error != null) {
      return Center(
        child: Text(
          attendanceProvider.error!,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red),
        ),
      );
    }

    if (authProvider.user?.role == 'student') {
      return _buildStudentView(context, attendanceProvider);
    } else {
      return _buildFacultyAdminView(context, authProvider, attendanceProvider);
    }
  }

  Widget _buildStudentView(BuildContext context, AttendanceProvider attendanceProvider) {
    final overallAttendance = _calculateOverallAttendance(attendanceProvider.attendanceSummaries);

    return RefreshIndicator(
      onRefresh: () async {
        await attendanceProvider.loadStudentAttendance(context.read<AuthProvider>().user!.id);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Overall Attendance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: SfCircularChart(
                      series: <CircularSeries>[
                        DoughnutSeries<double, String>(
                          dataSource: [overallAttendance, 100 - overallAttendance],
                          xValueMapper: (_, index) => index == 0 ? 'Present' : 'Absent',
                          yValueMapper: (data, _) => data,
                          pointColorMapper: (_, index) => index == 0 ? Theme.of(context).primaryColor : Colors.red,
                          innerRadius: '70%',
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                        )
                      ],
                      annotations: <CircularChartAnnotation>[
                        CircularChartAnnotation(
                          widget: Text(
                            '${overallAttendance.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'By Subject',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(maximum: 100),
                series: <CartesianSeries>[
                  BarSeries<Map<String, dynamic>, String>(
                    dataSource: attendanceProvider.attendanceSummaries
                        .map((summary) => {
                      'subjectName': summary.subjectName,
                      'percentage': summary.percentage,
                    })
                        .toList(),
                    xValueMapper: (data, _) => data['subjectName'],
                    yValueMapper: (data, _) => data['percentage'],
                    pointColorMapper: (data, _) =>
                    data['percentage'] < 75 ? Colors.orange : Theme.of(context).primaryColor,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recent Records',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (attendanceProvider.attendanceRecords.isEmpty)
              const Text('No attendance records found'),
            ...attendanceProvider.attendanceRecords
                .take(5)
                .map((record) => AttendanceCard(attendance: record)),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyAdminView(
      BuildContext context, AuthProvider authProvider, AttendanceProvider attendanceProvider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAvailableSubjects(authProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final availableSubjects = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                decoration: AppTheme.inputDecoration(label: 'Select Subject'),
                value: _selectedSubjectId,
                items: availableSubjects
                    .map<DropdownMenuItem<String>>((subject) => DropdownMenuItem<String>(
                  value: subject['id'] as String,
                  child: Text(subject['name'] as String),
                ))
                    .toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                  if (value != null) {
                    attendanceProvider.loadSubjectAttendance(value);
                  }
                },
              ),
            ),
            if (_selectedSubjectId != null && attendanceProvider.attendanceRecords.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attendanceProvider.attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = attendanceProvider.attendanceRecords[index];
                    return AttendanceCard(
                      attendance: record,
                      onEdit: () => _editAttendance(context, record),
                      onDelete: () => _deleteAttendance(context, record),
                    );
                  },
                ),
              ),
            if (_selectedSubjectId != null && attendanceProvider.attendanceRecords.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attendanceProvider.attendanceRecords.length,
                  itemBuilder: (context, index) {
                    return AttendanceCard(
                        attendance: attendanceProvider.attendanceRecords[index]);
                  },
                ),
              ),
            if (_selectedSubjectId != null && attendanceProvider.attendanceRecords.isEmpty)
              const Expanded(
                child: Center(child: Text('No attendance records for this subject')),
              ),
            if (_selectedSubjectId == null)
              const Expanded(
                child: Center(child: Text('Please select a subject')),
              ),
          ],
        );
      },
    );
  }

  Future<void> _editAttendance(BuildContext context, Attendance record) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Student: ${record.studentName}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: record.status,
              items: ['Present', 'Absent', 'Late'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, record.status),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != record.status) {
      final attendanceProvider = context.read<AttendanceProvider>();
      try {
        await attendanceProvider.updateAttendance(
          attendanceId: record.id,
          newStatus: result as String,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update attendance: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAttendance(BuildContext context, Attendance record) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this attendance record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final attendanceProvider = context.read<AttendanceProvider>();
      try {
        await attendanceProvider.deleteAttendance(record.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete attendance: ${e.toString()}')),
        );
      }
    }
  }

  double _calculateOverallAttendance(List<AttendanceSummary> summaries) {
    if (summaries.isEmpty) return 0;
    final totalClasses = summaries.fold(0, (sum, item) => sum + item.totalClasses);
    final attendedClasses = summaries.fold(0, (sum, item) => sum + item.attendedClasses);
    return (attendedClasses / totalClasses) * 100;
  }

  Future<void> _navigateToMarkAttendance(BuildContext context) async {
    try {
      final attendanceProvider = context.read<AttendanceProvider>();

      if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid subject first')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get subject name first
      final subjectDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_selectedSubjectId)
          .get();

      if (!subjectDoc.exists) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected subject not found')),
        );
        return;
      }

      final subjectName = subjectDoc.data()?['name'] as String? ?? 'Unknown Subject';

      // Get students for subject
      final students = await attendanceProvider.getStudentsForSubject(_selectedSubjectId!);

      Navigator.pop(context); // Remove loading dialog

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students enrolled in this subject')),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkAttendanceScreen(
            subjectId: _selectedSubjectId!,
            subjectName: subjectName,
            students: students, // Pass the List<Student> directly
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Remove loading dialog in case of error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: ${e.toString()}')),
      );
      debugPrint('Error in _navigateToMarkAttendance: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableSubjects(AuthProvider authProvider) async {
    try {
      // For faculty, fetch only their assigned subjects
      if (authProvider.user?.role == 'faculty') {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('subjects')
            .where('facultyId', isEqualTo: authProvider.user?.id)
            .get();

        return querySnapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc.data()['name']})
            .toList();
      }

      // For admin, fetch all subjects
      if (authProvider.user?.isAdmin == true) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('subjects')
            .get();

        return querySnapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc.data()['name']})
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      return [];
    }
  }
}