import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/enrollment.dart';

class EnrollmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Enrollment>> getStudentEnrollments(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('isApproved', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) => Enrollment.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching enrollments: $e');
    }
  }

  Future<List<Enrollment>> getSubjectEnrollments(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('subjectId', isEqualTo: subjectId)
          .where('isApproved', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) => Enrollment.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching subject enrollments: $e');
    }
  }

  Future<void> enrollStudent({
    required String studentId,
    required String studentName,
    required String subjectId,
    required String subjectName,
    required String courseId,
    required String batchId,
    required String classId,
  }) async {
    try {
      await _firestore.collection('enrollments').add({
        'studentId': studentId,
        'studentName': studentName,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'courseId': courseId,
        'batchId': batchId,
        'classId': classId,
        'isApproved': false, // Needs approval by admin/faculty
        'enrolledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error enrolling student: $e');
    }
  }

  Future<void> approveEnrollment(String enrollmentId) async {
    try {
      await _firestore.collection('enrollments').doc(enrollmentId).update({
        'isApproved': true,
      });
    } catch (e) {
      throw Exception('Error approving enrollment: $e');
    }
  }
}