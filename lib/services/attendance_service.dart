import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/attendance.dart';

import 'enrollment_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Attendance>> getStudentAttendance(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Attendance.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching attendance: $e');
    }
  }

  Future<List<Attendance>> getSubjectAttendance(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendance')
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Attendance.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching subject attendance: $e');
    }
  }

  Future<List<AttendanceSummary>> getStudentAttendanceSummary(String studentId) async {
    try {
      final attendance = await getStudentAttendance(studentId);
      final summaries = <AttendanceSummary>[];

      // Group by subject
      final subjectGroups = <String, List<Attendance>>{};
      for (final record in attendance) {
        subjectGroups.putIfAbsent(record.subjectId, () => []).add(record);
      }

      // Calculate summary for each subject
      for (final entry in subjectGroups.entries) {
        final subjectId = entry.key;
        final records = entry.value;
        final subjectName = records.first.subjectName;
        final total = records.length;
        final attended = records.where((r) => r.status == 'Present').length;
        final percentage = (attended / total) * 100;

        summaries.add(AttendanceSummary(
          subjectId: subjectId,
          subjectName: subjectName,
          totalClasses: total,
          attendedClasses: attended,
          percentage: percentage,
        ));
      }

      return summaries;
    } catch (e) {
      throw Exception('Error calculating attendance summary: $e');
    }
  }

  Future<void> markAttendance({
    required String subjectId,
    required String subjectName,
    required DateTime date,
    required List<Map<String, dynamic>> students,
    String? facultyId,
    String? facultyName,
    String? classId,
    String? batchId,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final student in students) {
        final docRef = _firestore.collection('attendance').doc();
        batch.set(docRef, {
          'subjectId': subjectId,
          'subjectName': subjectName,
          'status': student['status'] ?? 'Absent',
          'date': Timestamp.fromDate(date),
          'studentId': student['id'],
          'studentName': student['name'],
          if (facultyId != null) 'facultyId': facultyId,
          if (facultyName != null) 'facultyName': facultyName,
          if (classId != null) 'classId': classId,
          if (batchId != null) 'batchId': batchId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error marking attendance: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsForSubject(String subjectId) async {
    try {
      final enrollmentService = EnrollmentService();
      final enrollments = await enrollmentService.getSubjectEnrollments(subjectId);

      final students = <Map<String, dynamic>>[];
      for (final enrollment in enrollments) {
        final studentDoc = await _firestore.collection('users').doc(enrollment.studentId).get();
        students.add({
          'id': enrollment.studentId,
          'name': enrollment.studentName,
          'enrollmentNumber': studentDoc['enrollmentNumber'],
        });
      }

      return students;
    } catch (e) {
      throw Exception('Error fetching students for subject: $e');
    }
  }
}