import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:iic_connect/providers/attendance_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';
import 'package:iic_connect/models/student.dart';
import 'package:iic_connect/models/attendance.dart';
import 'package:iic_connect/widgets/attendance_card.dart';
import 'package:iic_connect/screens/attendance/mark_attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedSubjectId;
  bool _initialLoadComplete = false;
  final TextEditingController _searchController = TextEditingController();
  Student? _selectedStudent;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

  Widget _buildBody(
    BuildContext context,
    AuthProvider authProvider,
    AttendanceProvider attendanceProvider,
  ) {
    if (attendanceProvider.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (attendanceProvider.error != null) {
      return Center(
        child: Text(
          attendanceProvider.error!,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.red),
        ),
      );
    }

    if (authProvider.user?.role == 'student') {
      return _buildStudentView(context, attendanceProvider);
    } else {
      return _buildFacultyAdminView(context, authProvider, attendanceProvider);
    }
  }

  Widget _buildStudentView(
    BuildContext context,
    AttendanceProvider attendanceProvider,
  ) {
    final overallAttendance = _calculateOverallAttendance(
      attendanceProvider.attendanceSummaries,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await attendanceProvider.loadStudentAttendance(
          context.read<AuthProvider>().user!.id,
        );
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.orange),
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
                          dataSource: [
                            overallAttendance,
                            100 - overallAttendance,
                          ],
                          xValueMapper:
                              (_, index) => index == 0 ? 'Present' : 'Absent',
                          yValueMapper: (data, _) => data,
                          pointColorMapper:
                              (_, index) =>
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
                            style: Theme.of(
                              context,
                            ).textTheme.displayLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('By Subject', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(maximum: 100),
                series: <CartesianSeries>[
                  BarSeries<Map<String, dynamic>, String>(
                    dataSource:
                        attendanceProvider.attendanceSummaries
                            .map(
                              (summary) => {
                                'subjectName': summary.subjectName,
                                'percentage': summary.percentage,
                              },
                            )
                            .toList(),
                    xValueMapper: (data, _) => data['subjectName'],
                    yValueMapper: (data, _) => data['percentage'],
                    pointColorMapper:
                        (data, _) =>
                            data['percentage'] < 75
                                ? Colors.orange
                                : Theme.of(context).primaryColor,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
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
    BuildContext context,
    AuthProvider authProvider,
    AttendanceProvider attendanceProvider,
  ) {
    return Column(
      children: [
        // Search Box
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name or enrollment',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                            _selectedStudent = null;
                          });
                        },
                      )
                      : null,
            ),
            onChanged: (value) => _filterStudents(value, attendanceProvider),
          ),
        ),

        // Subject Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchAvailableSubjects(authProvider),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final availableSubjects = snapshot.data ?? [];
              return DropdownButtonFormField<String>(
                decoration: AppTheme.inputDecoration(label: 'Select Subject'),
                value: _selectedSubjectId,
                items:
                    availableSubjects
                        .map<DropdownMenuItem<String>>(
                          (subject) => DropdownMenuItem<String>(
                            value: subject['id'] as String,
                            child: Text(subject['name'] as String),
                          ),
                        )
                        .toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedSubjectId = value;
                    _isSearching = false;
                    _selectedStudent = null;
                  });
                  if (value != null) {
                    attendanceProvider.loadSubjectAttendance(value);
                  }
                },
              );
            },
          ),
        ),

        // Display based on search or list
        if (_isSearching && _selectedStudent != null)
          _buildStudentAttendanceView(_selectedStudent!, attendanceProvider)
        else if (_selectedSubjectId != null)
          _buildAttendanceListView(attendanceProvider)
        else
          const Expanded(child: Center(child: Text('Please select a subject'))),
      ],
    );
  }

  Widget _buildStudentAttendanceView(
    Student student,
    AttendanceProvider attendanceProvider,
  ) {
    final records =
        attendanceProvider.attendanceRecords
            .where((record) => record.studentId == student.id)
            .toList();

    final presentCount = records.where((r) => r.status == 'Present').length;
    final totalCount = records.length;
    final percentage = totalCount > 0 ? (presentCount / totalCount * 100) : 0;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${student.name} (${student.enrollmentNumber ?? 'N/A'})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: SfCircularChart(
                      series: <CircularSeries>[
                        DoughnutSeries<double, String>(
                          dataSource: [percentage.toDouble(), 100 - percentage.toDouble()],
                          xValueMapper:
                              (_, index) => index == 0 ? 'Present' : 'Absent',
                          yValueMapper: (data, _) => data,
                          pointColorMapper:
                              (_, index) =>
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
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(
                              context,
                            ).textTheme.displayLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Present: $presentCount / $totalCount classes',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Attendance Records',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...records.map((record) => AttendanceCard(attendance: record)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceListView(AttendanceProvider attendanceProvider) {
    return Expanded(
      child:
          attendanceProvider.attendanceRecords.isEmpty
              ? const Center(
                child: Text('No attendance records for this subject'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: attendanceProvider.attendanceRecords.length,
                itemBuilder: (context, index) {
                  return AttendanceCard(
                    attendance: attendanceProvider.attendanceRecords[index],
                  );
                },
              ),
    );
  }

  void _filterStudents(String query, AttendanceProvider attendanceProvider) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _selectedStudent = null;
      });
      return;
    }

    if (_selectedSubjectId == null) return;

    // Get unique students from attendance records
    final studentMap = <String, Student>{};
    for (var record in attendanceProvider.attendanceRecords) {
      if (!studentMap.containsKey(record.studentId)) {
        studentMap[record.studentId] = Student(
          id: record.studentId,
          name: record.studentName,
          enrollmentNumber: '', // Will be updated below if available
        );
      }
    }

    // Filter students based on search query
    final filtered =
        studentMap.values.where((student) {
          final nameMatch = student.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          final enrollmentMatch =
              student.enrollmentNumber?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          return nameMatch || enrollmentMatch;
        }).toList();

    setState(() {
      _isSearching = true;
      if (filtered.length == 1) {
        _selectedStudent = filtered.first;
        _getStudentDetails(_selectedStudent!.id);
      } else if (filtered.isEmpty) {
        _selectedStudent = null;
      } else {
        _showStudentSelectionDialog(filtered);
      }
    });
  }

  Future<void> _getStudentDetails(String studentId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();

      if (doc.exists) {
        setState(() {
          _selectedStudent = Student.fromFirestore(doc);
        });
      }
    } catch (e) {
      debugPrint('Error fetching student details: $e');
    }
  }

  Future<void> _showStudentSelectionDialog(List<Student> students) async {
    final selectedStudent = await showDialog<Student>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Student'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    title: Text(student.name),
                    subtitle: Text(student.enrollmentNumber ?? ''),
                    onTap: () => Navigator.pop(context, student),
                  );
                },
              ),
            ),
          ),
    );

    if (selectedStudent != null) {
      setState(() {
        _selectedStudent = selectedStudent;
      });
      _getStudentDetails(selectedStudent.id);
    }
  }

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

  Future<void> _navigateToMarkAttendance(BuildContext context) async {
    try {
      final attendanceProvider = context.read<AttendanceProvider>();

      if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid subject first')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final subjectDoc =
          await FirebaseFirestore.instance
              .collection('subjects')
              .doc(_selectedSubjectId)
              .get();

      if (!subjectDoc.exists) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected subject not found')),
        );
        return;
      }

      final subjectName =
          subjectDoc.data()?['name'] as String? ?? 'Unknown Subject';
      final students = await attendanceProvider.getStudentsForSubject(
        _selectedSubjectId!,
      );

      Navigator.pop(context);

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students enrolled in this subject')),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MarkAttendanceScreen(
                subjectId: _selectedSubjectId!,
                subjectName: subjectName,
                students: students,
              ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: ${e.toString()}')),
      );
      debugPrint('Error in _navigateToMarkAttendance: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableSubjects(
      AuthProvider authProvider,
      ) async {
    try {
      if (authProvider.user?.role == 'faculty') {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('subjects')
            .where('facultyId', isEqualTo: authProvider.user?.id)
            .get();

        return querySnapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc.data()['name']})
            .toList();
      }

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
