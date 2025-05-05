import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iic_connect/models/notice.dart';
import 'package:iic_connect/services/notice_service.dart';

class NoticeProvider with ChangeNotifier {
  final NoticeService _noticeService = NoticeService();

  List<Notice> _notices = [];
  Notice? _currentNotice;
  bool _isLoading = false;
  String? _error;

  List<Notice> get notices => _notices;
  Notice? get currentNotice => _currentNotice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notices = await _noticeService.getNotices();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<Notice?> fetchNoticeDetails(String noticeId) async {
    _isLoading = true;
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('notices')
          .doc(noticeId)
          .get();

      if (!doc.exists) {
        _error = 'Notice not found';
        _currentNotice = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return null;
      }

      _currentNotice = Notice.fromFirestore(doc.data()!, doc.id);
      _error = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return _currentNotice;
    } catch (e) {
      _error = e.toString();
      _currentNotice = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return null;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> createNotice(Notice notice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _noticeService.createNotice(notice);
      await fetchNotices(); // Refresh the notices list
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNotice(String noticeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First get the notice to verify permissions
      final notice = await fetchNoticeDetails(noticeId);

      // Additional check - in case security rules fail
      if (notice != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final isAdmin = userDoc.data()?['isAdmin'] ?? false;
        final userRole = userDoc.data()?['role'] ?? '';

        if (!isAdmin && userRole != 'staff' && notice.postedBy != user.uid) {
          throw Exception('Unauthorized to delete this notice');
        }
      }

      await _noticeService.deleteNotice(noticeId);
      _notices.removeWhere((notice) => notice.id == noticeId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}