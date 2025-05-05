import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/subject_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final Set<String> _selectedSubjects = {};
  bool _isInitialLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) {
      _isInitialLoad = false;
      // Load subjects when screen first opens
      Provider.of<SubjectProvider>(context, listen: false).loadAllSubjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (subjectProvider.isLoading && subjectProvider.subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Enroll in Subjects')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Subjects for Your Batch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (subjectProvider.subjects.isEmpty)
              const Text('No subjects available for enrollment'),
            ...subjectProvider.subjects.map((subject) =>
                _buildSubjectCard(subject)),
            const SizedBox(height: 16),
            if (_selectedSubjects.isNotEmpty)
              ElevatedButton(
                onPressed: () => _submitEnrollments(context),
                child: const Text('Submit Enrollment Requests'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return GlassCard(
      child: CheckboxListTile(
        title: Text(subject['name']),
        subtitle: Text(subject['code']),
        value: _selectedSubjects.contains(subject['id']),
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedSubjects.add(subject['id']);
            } else {
              _selectedSubjects.remove(subject['id']);
            }
          });
        },
      ),
    );
  }

  Future<void> _submitEnrollments(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final subjectProvider = context.read<SubjectProvider>();

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final subjectId in _selectedSubjects) {
        final subject = subjectProvider.subjects.firstWhere(
                (s) => s['id'] == subjectId);

        final enrollmentRef = FirebaseFirestore.instance
            .collection('enrollments')
            .doc();

        batch.set(enrollmentRef, {
          'studentId': authProvider.user!.id,
          'studentName': authProvider.user!.name,
          'subjectId': subjectId,
          'subjectName': subject['name'],
          'courseId': subject['courseId'],
          'batchId': authProvider.user!.batch,
          'classId': authProvider.user!.classId,
          'isApproved': false,
          'requestedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment requests submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting enrollments: $e')),
      );
    }
  }
}