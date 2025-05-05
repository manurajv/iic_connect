import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String? attachmentUrl;
  final String postedBy;
  final String postedByName;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    this.attachmentUrl,
    required this.postedBy,
    required this.postedByName,
  });

  factory Notice.fromFirestore(Map<String, dynamic> data, String id) {
    return Notice(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      date: (data['date'] as Timestamp).toDate(),
      attachmentUrl: data['attachmentUrl'],
      postedBy: data['postedBy'] ?? 'Admin',
      postedByName: data['postedByName'] ?? 'Admin',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      'postedBy': postedBy,
      'postedByName': postedByName,
    };
  }

  Notice copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? date,
    String? attachmentUrl,
    String? postedBy,
    String? postedByName,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      postedBy: postedBy ?? this.postedBy,
      postedByName: postedByName ?? this.postedByName,
    );
  }
}