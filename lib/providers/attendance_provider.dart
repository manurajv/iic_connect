import 'package:flutter/material.dart';
import 'package:iic_connect/models/attendance.dart';
import 'package:iic_connect/services/attendance_service.dart';
import 'package:iic_connect/providers/auth_provider.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
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

  Future<List<Map<String, dynamic>>> getStudentsForSubject(String subjectId) async {
    try {
      return await _attendanceService.getStudentsForSubject(subjectId);
    } catch (e) {
      _error = 'Failed to get students: ${e.toString()}';
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}