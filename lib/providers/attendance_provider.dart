import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iic_connect/models/attendance.dart';
import 'package:iic_connect/services/attendance_service.dart';
import 'package:iic_connect/models/student.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Attendance> _attendanceRecords = [];
  List<AttendanceSummary> _attendanceSummaries = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedStudentId;
  String? _selectedSubjectId;

  List<Attendance> get attendanceRecords => _attendanceRecords;
  List<AttendanceSummary> get attendanceSummaries => _attendanceSummaries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedStudentId => _selectedStudentId;
  String? get selectedSubjectId => _selectedSubjectId;

  Future<void> loadStudentAttendance(String studentId) async {
    _isLoading = true;
    _selectedStudentId = studentId;
    _error = null;
    notifyListeners();

    try {
      _attendanceRecords = await _attendanceService.getStudentAttendance(studentId);
      _attendanceSummaries = await _attendanceService.getStudentAttendanceSummary(studentId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load attendance: ${e.toString()}';
      _attendanceRecords = [];
      _attendanceSummaries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubjectAttendance(String subjectId) async {
    _isLoading = true;
    _selectedSubjectId = subjectId;
    notifyListeners();

    try {
      _attendanceRecords = await _attendanceService.getSubjectAttendance(subjectId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load subject attendance: ${e.toString()}';
      _attendanceRecords = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    notifyListeners();

    try {
      await _attendanceService.markAttendance(
        subjectId: subjectId,
        subjectName: subjectName,
        date: date,
        students: students,
        facultyId: facultyId,
        facultyName: facultyName,
        classId: classId,
        batchId: batchId,
      );

      // Refresh data after marking attendance
      if (_selectedStudentId != null) {
        await loadStudentAttendance(_selectedStudentId!);
      } else if (_selectedSubjectId != null) {
        await loadSubjectAttendance(_selectedSubjectId!);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to mark attendance: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Student>> getStudentsForSubject(String subjectId) async {
    try {
      if (subjectId.isEmpty) {
        throw Exception('Subject ID cannot be empty');
      }

      // First get enrollments for this subject
      final enrollmentQuery = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      // Extract valid student IDs
      final studentIds = enrollmentQuery.docs
          .map((doc) => doc.data()['studentId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet() // Remove duplicates
          .toList();

      if (studentIds.isEmpty) {
        return [];
      }

      // Then get student details in a single batch query
      final studentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      return studentsQuery.docs
          .map((doc) => Student.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting students for subject $subjectId: $e');
      throw Exception('Failed to fetch students: ${e.toString()}');
    }
  }

  Future<void> updateAttendance({
    required String attendanceId,
    required String newStatus,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('attendance').doc(attendanceId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the data
      if (_selectedStudentId != null) {
        await loadStudentAttendance(_selectedStudentId!);
      } else if (_selectedSubjectId != null) {
        await loadSubjectAttendance(_selectedSubjectId!);
      }
    } catch (e) {
      _error = 'Failed to update attendance: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAttendance(String attendanceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('attendance').doc(attendanceId).delete();

      // Refresh the data
      if (_selectedStudentId != null) {
        await loadStudentAttendance(_selectedStudentId!);
      } else if (_selectedSubjectId != null) {
        await loadSubjectAttendance(_selectedSubjectId!);
      }
    } catch (e) {
      _error = 'Failed to delete attendance: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}