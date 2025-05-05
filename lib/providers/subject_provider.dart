import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubjectProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get subjects => _subjects;
  bool get isLoading => _isLoading;

  Future<void> loadAllSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore.collection('subjects').get();
      _subjects = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading subjects: $e');
      _subjects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubjectsForFaculty(String facultyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('subjects')
          .where('facultyId', isEqualTo: facultyId)
          .get();

      _subjects = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading faculty subjects: $e');
      _subjects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignFacultyToSubject(String subjectId, String facultyId) async {
    try {
      await _firestore.collection('subjects').doc(subjectId).update({
        'facultyId': facultyId,
      });
      // Refresh the list
      await loadAllSubjects();
    } catch (e) {
      debugPrint('Error assigning faculty: $e');
      rethrow;
    }
  }
}