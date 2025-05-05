import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/lab.dart';
import 'package:iic_connect/services/lab_service.dart';

class LabProvider with ChangeNotifier {
  final LabService _labService = LabService();
  List<Lab> _labs = [];
  bool _isLoading = false;

  List<Lab> get labs => _labs;
  bool get isLoading => _isLoading;

  Future<void> fetchLabs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _labs = await _labService.getLabs();
    } catch (e) {
      _labs = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> bookLab(Map<String, dynamic> bookingData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _labService.bookLab(bookingData);
      await fetchLabs(); // Refresh labs
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}