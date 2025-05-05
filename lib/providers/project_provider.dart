import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/project.dart';

class ProjectProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> fetchProjects(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('projects')
          .where('studentId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _projects = snapshot.docs
          .map((doc) => Project.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _projects = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProjectUpdate(String projectId, String message) async {
    try {
      await _firestore.collection('project_updates').add({
        'projectId': projectId,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchProjects(projectId); // Refresh project data
    } catch (e) {
      rethrow;
    }
  }
}