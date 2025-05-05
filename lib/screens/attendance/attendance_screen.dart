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
import 'mark_attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    if (authProvider.user != null) {
      if (authProvider.user!.role == 'student') {
        await attendanceProvider.loadStudentAttendance(authProvider.user!.id);
      } else if (_selectedSubjectId != null) {
        await attendanceProvider.loadSubjectAttendance(_selectedSubjectId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

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
      onRefresh: () => attendanceProvider.loadStudentAttendance(context.read<AuthProvider>().user!.id),
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
                .map((record) => _buildAttendanceRecord(record)),
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
                    return _buildAttendanceRecord(
                        attendanceProvider.attendanceRecords[index]);
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

  Widget _buildAttendanceRecord(Attendance record) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            record.status == 'Present' ? Icons.check_circle : Icons.cancel,
            color: record.status == 'Present' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subjectName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${record.date.day}/${record.date.month}/${record.date.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (context.read<AuthProvider>().user?.role != 'student')
                  Text(
                    record.studentName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateOverallAttendance(List<AttendanceSummary> summaries) {
    if (summaries.isEmpty) return 0;
    final totalClasses = summaries.fold(0, (sum, item) => sum + item.totalClasses);
    final attendedClasses = summaries.fold(0, (sum, item) => sum + item.attendedClasses);
    return (attendedClasses / totalClasses) * 100;
  }

  Future<void> _navigateToMarkAttendance(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    final students = await attendanceProvider.getStudentsForSubject(_selectedSubjectId!);

    // Get subject name from Firestore
    final subjectDoc = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(_selectedSubjectId)
        .get();
    final subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendanceScreen(
          subjectId: _selectedSubjectId!,
          subjectName: subjectName,
          students: students,
        ),
      ),
    );
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