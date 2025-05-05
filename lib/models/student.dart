import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String? email;
  final String? enrollmentNumber;
  final String? department;
  final String? phone;
  final String? profileImage;
  final Timestamp? createdAt;
  final String? batch;
  final String? section;
  final String? course;
  final String? classId;

  Student({
    required this.id,
    required this.name,
    this.email,
    this.enrollmentNumber,
    this.department,
    this.phone,
    this.profileImage,
    this.createdAt,
    this.batch,
    this.section,
    this.course,
    this.classId,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Student(
      id: doc.id,
      name: data['name'] ?? 'Unknown Student',
      email: data['email'],
      enrollmentNumber: data['enrollmentNumber'],
      department: data['department'],
      phone: data['phone'],
      profileImage: data['profileImage'],
      createdAt: data['createdAt'],
      batch: data['batch'],
      section: data['section'],
      course: data['course'],
      classId: data['classId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (email != null) 'email': email,
      if (enrollmentNumber != null) 'enrollmentNumber': enrollmentNumber,
      if (department != null) 'department': department,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
      if (createdAt != null) 'createdAt': createdAt,
      if (batch != null) 'batch': batch,
      if (section != null) 'section': section,
      if (course != null) 'course': course,
      if (classId != null) 'classId': classId,
    };
  }
}