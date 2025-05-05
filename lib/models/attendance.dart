import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String subjectId;
  final String subjectName;
  final String status; // 'Present' or 'Absent'
  final DateTime date;
  final String studentId;
  final String studentName;
  final String? facultyId;
  final String? facultyName;
  final String? classId;
  final String? batchId;
  final Timestamp createdAt;

  Attendance({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.status,
    required this.date,
    required this.studentId,
    required this.studentName,
    this.facultyId,
    this.facultyName,
    this.classId,
    this.batchId,
    required this.createdAt,
  });

  factory Attendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Attendance(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      status: data['status'] ?? 'Absent',
      date: (data['date'] as Timestamp).toDate(),
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      facultyId: data['facultyId'],
      facultyName: data['facultyName'],
      classId: data['classId'],
      batchId: data['batchId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'status': status,
      'date': Timestamp.fromDate(date),
      'studentId': studentId,
      'studentName': studentName,
      if (facultyId != null) 'facultyId': facultyId,
      if (facultyName != null) 'facultyName': facultyName,
      if (classId != null) 'classId': classId,
      if (batchId != null) 'batchId': batchId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class AttendanceSummary {
  final String subjectId;
  final String subjectName;
  final int totalClasses;
  final int attendedClasses;
  final double percentage;

  AttendanceSummary({
    required this.subjectId,
    required this.subjectName,
    required this.totalClasses,
    required this.attendedClasses,
    required this.percentage,
  });
}