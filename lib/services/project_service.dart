import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/project.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Project>> getProjectsByStudent(String studentId) async {
    final snapshot = await _firestore
        .collection('projects')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Project.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> addProjectUpdate(String projectId, ProjectUpdate update) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('updates')
        .add(update.toFirestore());
  }
}