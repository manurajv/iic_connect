import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/lab.dart';
import 'package:iic_connect/models/lab_booking.dart';

class LabService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Lab>> getLabs() async {
    final snapshot = await _firestore.collection('labs').get();
    return snapshot.docs.map((doc) => Lab.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<LabBooking> bookLab(Map<String, dynamic> bookingData) async {
    final docRef = await _firestore.collection('lab_bookings').add({
      ...bookingData,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return LabBooking.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }
}