import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/academic_model.dart';


class AcademicProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Batch> _batches = [];
  List<Class> _classes = [];
  List<Course> _courses = [];
  List<Subject> _subjects = [];
  bool _isLoading = false;
  List<Faculty> _facultyMembers = [];


  List<Batch> get batches => _batches;
  List<Class> get classes => _classes;
  List<Course> get courses => _courses;
  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  List<Faculty> get facultyMembers => _facultyMembers;

  // Batch CRUD Operations
  Future<void> fetchBatches() async {
    if (_batches.isNotEmpty) return; // Skip if already loaded

    _isLoading = true;
    try {
      final snapshot = await _firestore.collection('batches').get();
      _batches = snapshot.docs.map((doc) => Batch.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to fetch batches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBatch(String name) async {
    try {
      await _firestore.collection('batches').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchBatches();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBatch(String id, String name) async {
    try {
      await _firestore.collection('batches').doc(id).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await fetchBatches();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      await _firestore.collection('batches').doc(id).delete();
      await fetchBatches();
    } catch (e) {
      rethrow;
    }
  }

  // Class CRUD Operations
  Future<void> fetchClasses() async {
    if (_classes.isNotEmpty) return;

    _isLoading = true;
    try {
      final snapshot = await _firestore.collection('classes').get();
      _classes = snapshot.docs.map((doc) => Class.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to fetch classes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClass(String name, String batchId) async {
    try {
      await _firestore.collection('classes').add({
        'name': name,
        'batchId': batchId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchClasses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClass(String id, String name, String batchId) async {
    try {
      await _firestore.collection('classes').doc(id).update({
        'name': name,
        'batchId': batchId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await fetchClasses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      await _firestore.collection('classes').doc(id).delete();
      await fetchClasses();
    } catch (e) {
      rethrow;
    }
  }

  // Course CRUD Operations
  Future<void> fetchCourses() async {
    if (_courses.isNotEmpty) return;

    _isLoading = true;
    try {
      final snapshot = await _firestore.collection('courses').get();
      _courses = snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to fetch courses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCourse(String name, String code) async {
    try {
      await _firestore.collection('courses').add({
        'name': name,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchCourses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCourse(String id, String name, String code) async {
    try {
      await _firestore.collection('courses').doc(id).update({
        'name': name,
        'code': code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await fetchCourses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await _firestore.collection('courses').doc(id).delete();
      await fetchCourses();
    } catch (e) {
      rethrow;
    }
  }

  // Subject CRUD Operations
  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance.collection('subjects').get();
      _subjects = snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      _subjects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubject(
      String name,
      String code,
      String batchId,
      String classId,
      String facultyId,
      ) async {
    try {
      await FirebaseFirestore.instance.collection('subjects').add({
        'name': name,
        'code': code,
        'batchId': batchId,
        'classId': classId,
        'facultyId': facultyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchSubjects();
    } catch (e) {
      debugPrint('Error adding subject: $e');
      rethrow;
    }
  }

  Future<void> updateSubject(
      String id,
      String name,
      String code,
      String batchId,
      String classId,
      String facultyId,
      ) async {
    try {
      await FirebaseFirestore.instance.collection('subjects').doc(id).update({
        'name': name,
        'code': code,
        'batchId': batchId,
        'classId': classId,
        'facultyId': facultyId,
      });
      await fetchSubjects();
    } catch (e) {
      debugPrint('Error updating subject: $e');
      rethrow;
    }
  }


  Future<void> deleteSubject(String id) async {
    try {
      await FirebaseFirestore.instance.collection('subjects').doc(id).delete();
      await fetchSubjects();
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      rethrow;
    }
  }

  Future<void> fetchFacultyMembers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('faculty').get();
      _facultyMembers = snapshot.docs.map((doc) => Faculty.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to fetch faculty: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFacultyMember(String name, String email, String facultyId) async {
    try {
      await _firestore.collection('faculty').add({
        'name': name,
        'email': email,
        'facultyId': facultyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchFacultyMembers();
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods
  List<Class> getClassesByBatch(String batchId) {
    return _classes.where((classItem) => classItem.batchId == batchId).toList();
  }

  // List<Subject> getSubjectsByCourse(String courseId) {
  //   return _subjects.where((subject) => subject.courseId == courseId).toList();
  // }

  List<Subject> getSubjectsByClass(String classId) {
    return _subjects.where((subject) => subject.classId == classId).toList();
  }
}