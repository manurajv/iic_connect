import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/notice.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Notice>> getNotices() async {
    final snapshot = await _firestore
        .collection('notices')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Notice.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> createNotice(Notice notice) async {
    await _firestore.collection('notices').add(notice.toFirestore());
  }

  Future<Notice> getNoticeById(String id) async {
    final doc = await _firestore.collection('notices').doc(id).get();
    return Notice.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> deleteNotice(String id) async {
    await _firestore.collection('notices').doc(id).delete();
  }
}