import 'package:cloud_firestore/cloud_firestore.dart';

class Batch {
  final String id;
  final String name;
  final Timestamp createdAt;

  Batch({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Batch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Batch(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt,
    };
  }
}

class Class {
  final String id;
  final String name;
  final String batchId;
  final Timestamp createdAt;

  Class({
    required this.id,
    required this.name,
    required this.batchId,
    required this.createdAt,
  });

  factory Class.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Class(
      id: doc.id,
      name: data['name'] ?? '',
      batchId: data['batchId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'batchId': batchId,
      'createdAt': createdAt,
    };
  }
}

class Course {
  final String id;
  final String code;
  final String name;
  final Timestamp createdAt;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'createdAt': createdAt,
    };
  }
}

class Subject {
  final String id;
  final String name;
  final String code;
  final String batchId;
  final String classId;
  final String facultyId;
  final Timestamp createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.batchId,
    required this.classId,
    required this.facultyId,
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
      'createdAt': createdAt,
    };
  }
}

class Faculty {
  final String id;
  final String name;
  final String email;
  final String facultyId;
  final Timestamp createdAt;

  Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.facultyId,
    required this.createdAt,
  });

  factory Faculty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Faculty(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      facultyId: data['facultyId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'facultyId': facultyId,
      'createdAt': createdAt,
    };
  }
}