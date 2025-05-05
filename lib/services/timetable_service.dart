import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/timetable.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Timetable>> getTimetableForBatch(String batch) async {
    try {
      final querySnapshot = await _firestore
          .collection('timetables')
          .where('batch', isEqualTo: batch)
          .orderBy('startTime')
          .get();

      return querySnapshot.docs
          .map((doc) => Timetable.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch timetable for batch $batch: $e');
    }
  }

  Future<List<Timetable>> getTimetableForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('timetables')
          .where('createdBy', isEqualTo: userId)
          .orderBy('startTime')
          .get();

      return querySnapshot.docs
          .map((doc) => Timetable.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch timetable for user $userId: $e');
    }
  }

  Future<void> addTimetable(Timetable timetable) async {
    try {
      await _firestore.collection('timetables').add(timetable.toFirestore());
    } catch (e) {
      throw Exception('Failed to add timetable: $e');
    }
  }

  Future<void> deleteTimetable(String id) async {
    try {
      await _firestore.collection('timetables').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete timetable: $e');
    }
  }
}