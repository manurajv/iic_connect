import 'package:cloud_firestore/cloud_firestore.dart';

class Enrollment {
  final String id;
  final String studentId;
  final String studentName;
  final String subjectId;
  final String subjectName;
  final String courseId;
  final String batchId;
  final String classId;
  final Timestamp enrolledAt;
  final bool isApproved;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.subjectName,
    required this.courseId,
    required this.batchId,
    required this.classId,
    required this.enrolledAt,
    this.isApproved = false,
  });

  factory Enrollment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Enrollment(
      id: doc.id,
      studentId: data['studentId'],
      studentName: data['studentName'],
      subjectId: data['subjectId'],
      subjectName: data['subjectName'],
      courseId: data['courseId'],
      batchId: data['batchId'],
      classId: data['classId'],
      enrolledAt: data['enrolledAt'] ?? Timestamp.now(),
      isApproved: data['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'courseId': courseId,
      'batchId': batchId,
      'classId': classId,
      'enrolledAt': FieldValue.serverTimestamp(),
      'isApproved': isApproved,
    };
  }
}