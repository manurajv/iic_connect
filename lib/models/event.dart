import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String organizer;
  final int maxParticipants;
  final List<String> registeredParticipants;
  final String category;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.organizer,
    required this.maxParticipants,
    required this.registeredParticipants,
    required this.category,
  });

  factory Event.fromFirestore(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      organizer: data['organizer'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
      registeredParticipants:
      List<String>.from(data['registeredParticipants'] ?? []),
      category: data['category'] ?? 'general',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'organizer': organizer,
      'maxParticipants': maxParticipants,
      'registeredParticipants': registeredParticipants,
      'category': category,
    };
  }
}