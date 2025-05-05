import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/event.dart';

class EventProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Event> _events = [];
  bool _isLoading = false;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;

  Future<void> fetchEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('events')
          .where('endTime', isGreaterThan: Timestamp.now())
          .orderBy('endTime')
          .get();

      _events = snapshot.docs
          .map((doc) => Event.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _events = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> registerForEvent(String eventId, String userId) async {
  //   try {
  //     await _firestore.collection('event_registrations').add({
  //       'eventId': eventId,
  //       'userId': userId,
  //       'registeredAt': FieldValue.serverTimestamp(),
  //     });
  //     await fetchEvents(); // Refresh event data
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'registeredParticipants': FieldValue.arrayUnion([userId])
      });
      await fetchEvents(); // Refresh event data
    } catch (e) {
      rethrow;
    }
  }
}