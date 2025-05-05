import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Event>> getUpcomingEvents() async {
    final snapshot = await _firestore
        .collection('events')
        .where('endTime', isGreaterThan: Timestamp.now())
        .orderBy('endTime')
        .get();

    return snapshot.docs
        .map((doc) => Event.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> registerForEvent(String eventId, String userId) async {
    await _firestore.collection('event_registrations').add({
      'eventId': eventId,
      'userId': userId,
      'registeredAt': FieldValue.serverTimestamp(),
    });
  }
}