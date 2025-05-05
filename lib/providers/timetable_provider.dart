import 'package:flutter/material.dart';
import 'package:iic_connect/models/timetable.dart';
import 'package:iic_connect/services/timetable_service.dart';

class TimetableProvider with ChangeNotifier {
  final TimetableService _service = TimetableService();
  List<Timetable> _timetables = [];
  bool _isLoading = false;
  String? _error;

  List<Timetable> get timetables => _timetables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTimetable({String? userId, String? batch}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (userId != null) {
        _timetables = await _service.getTimetableForUser(userId);
      } else if (batch != null) {
        _timetables = await _service.getTimetableForBatch(batch);
      } else {
        throw Exception('Either userId or batch must be provided');
      }
    } catch (e) {
      _error = 'Failed to load timetable: ${e.toString()}';
      _timetables = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTimetable(Timetable timetable) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addTimetable(timetable);
      await fetchTimetable(userId: timetable.createdBy);
    } catch (e) {
      _error = 'Failed to add timetable: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTimetable(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteTimetable(id);
    } catch (e) {
      _error = 'Failed to delete timetable: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}