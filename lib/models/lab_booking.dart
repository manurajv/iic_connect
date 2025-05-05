import 'package:cloud_firestore/cloud_firestore.dart';

class LabBooking {
  final String id;
  final String labId;
  final String bookedBy;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose;
  final String status;

  LabBooking({
    required this.id,
    required this.labId,
    required this.bookedBy,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.status,
  });

  factory LabBooking.fromFirestore(Map<String, dynamic> data, String id) {
    return LabBooking(
      id: id,
      labId: data['labId'] ?? '',
      bookedBy: data['bookedBy'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'labId': labId,
      'bookedBy': bookedBy,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'purpose': purpose,
      'status': status,
    };
  }
}