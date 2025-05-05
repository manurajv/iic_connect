import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/lab_booking.dart';

class Lab {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final List<String> equipment;
  final List<LabBooking> bookings;

  Lab({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.equipment,
    required this.bookings,
  });

  factory Lab.fromFirestore(Map<String, dynamic> data, String id) {
    return Lab(
      id: id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      capacity: data['capacity'] ?? 0,
      equipment: List<String>.from(data['equipment'] ?? []),
      bookings: data['bookings'] != null
          ? (data['bookings'] as List).map((b) =>
          LabBooking.fromFirestore(b, '')).toList()
          : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'capacity': capacity,
      'equipment': equipment,
      'bookings': bookings.map((b) => b.toFirestore()).toList(),
    };
  }
}