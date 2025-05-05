import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final String studentId;
  final String facultyId;
  final String status;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ProjectUpdate> updates;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.studentId,
    required this.facultyId,
    required this.status,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    required this.updates,
  });

  factory Project.fromFirestore(Map<String, dynamic> data, String id) {
    return Project(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      studentId: data['studentId'] ?? '',
      facultyId: data['facultyId'] ?? '',
      status: data['status'] ?? 'pending',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      updates: List<ProjectUpdate>.from(
          (data['updates'] ?? []).map((u) => ProjectUpdate.fromFirestore(u, ''))),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'studentId': studentId,
      'facultyId': facultyId,
      'status': status,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'updates': updates.map((u) => u.toFirestore()).toList(),
    };
  }
}

class ProjectUpdate {
  final String id;
  final String message;
  final String authorId;
  final DateTime createdAt;
  final List<String> attachments;

  ProjectUpdate({
    required this.id,
    required this.message,
    required this.authorId,
    required this.createdAt,
    required this.attachments,
  });

  factory ProjectUpdate.fromFirestore(Map<String, dynamic> data, String id) {
    return ProjectUpdate(
      id: id,
      message: data['message'] ?? '',
      authorId: data['authorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
    };
  }
}