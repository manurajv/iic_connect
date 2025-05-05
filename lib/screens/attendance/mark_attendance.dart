import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/attendance_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final List<Map<String, dynamic>> students;

  const MarkAttendanceScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.students,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    // Initialize all students as present by default
    for (final student in widget.students) {
      _attendanceStatus[student['id']] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Mark Attendance - ${widget.subjectName}')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...widget.students.map((student) => _buildStudentAttendanceItem(student)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitAttendance,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Attendance'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceItem(Map<String, dynamic> student) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Checkbox(
            value: _attendanceStatus[student['id']] ?? false,
            onChanged: (value) {
              setState(() {
                _attendanceStatus[student['id']] = value!;
              });
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  student['enrollmentNumber'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    final students = widget.students.map((student) {
      return {
        'id': student['id'],
        'name': student['name'],
        'status': _attendanceStatus[student['id']] ?? false ? 'Present' : 'Absent',
      };
    }).toList();

    try {
      await attendanceProvider.markAttendance(
        subjectId: widget.subjectId,
        subjectName: widget.subjectName,
        date: _selectedDate,
        students: students,
        facultyId: authProvider.user?.id,
        facultyName: authProvider.user?.name,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: $e')),
      );
    }
  }
}