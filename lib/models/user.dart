import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? enrollmentNumber;
  final String? department;
  final String? phone;
  final String? profileImage;
  final Timestamp? createdAt;
  final String? batch;
  final String? section;
  final String? course;
  final String? classId;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.enrollmentNumber,
    this.department,
    this.phone,
    this.profileImage,
    this.createdAt,
    this.batch,
    this.section,
    this.course,
    this.classId,
    this.isAdmin = false,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      enrollmentNumber: data['enrollmentNumber'] ?? '',
      department: data['department'] ?? 'IIC',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'] ?? '',
      createdAt: data['createdAt'] ?? '',
      batch: data['batch'] ?? '',
      section: data['section'] ?? '',
      course: data['course'] ?? '',
      classId: data['class'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (enrollmentNumber != null) 'enrollmentNumber': enrollmentNumber,
      if (department != null) 'department': department,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      if (batch != null) 'batch': batch,
      if (section != null) 'section': section,
      if (course != null) 'course': course,
      if (classId != null) 'class': classId,
      'isAdmin': isAdmin,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? enrollmentNumber,
    String? department,
    String? phone,
    String? profileImage,
    Timestamp? createdAt,
    String? batch,
    String? section,
    String? course,
    String? classId,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      batch: batch ?? this.batch,
      section: section ?? this.section,
      course: course ?? this.course,
      classId: classId ?? this.classId,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  static Future<bool> checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final token = await user.getIdTokenResult(true);
      return token.claims?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  // static Future<bool> isAdmin(String uid) async {
  //   final user = await FirebaseAuth.instance.currentUser;
  //   if (user == null) return false;
  //
  //   await user.getIdToken(true);
  //   final token = await user.getIdTokenResult();
  //   return token.claims?['isAdmin'] == true;
  // }
}