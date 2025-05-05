import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final String code;
  final String batchId;
  final String classId;
  final String facultyId;
  final String? courseId;
  final Timestamp createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.batchId,
    required this.classId,
    required this.facultyId,
    required this.courseId,
    required this.createdAt,
  });

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      batchId: data['batchId'] ?? '',
      classId: data['classId'] ?? '',
      facultyId: data['facultyId'] ?? '',
      courseId: data['courseId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'batchId': batchId,
      'classId': classId,
      'facultyId': facultyId,
      'courseId': courseId,
      'createdAt': createdAt,
    };
  }
}