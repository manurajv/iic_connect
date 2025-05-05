import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/utils/constants.dart';
import 'package:intl/intl.dart';

class Timetable {
  final String id;
  final String courseCode;
  final String courseName;
  final String subjectName;
  final String subjectCode;
  final String faculty;
  final String room;
  final List<String> days;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? batch;
  final String? section;
  final String? className;
  final String? classId;
  final String createdBy;

  Timetable({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.subjectName,
    required this.subjectCode,
    required this.faculty,
    required this.room,
    required this.days,
    required this.startTime,
    required this.endTime,
    this.batch,
    this.section,
    this.className,
    this.classId,
    required this.createdBy,
  });

  factory Timetable.fromFirestore(Map<String, dynamic> data, String id) {
    final start = (data['startTime'] as Timestamp).toDate();
    final end = (data['endTime'] as Timestamp).toDate();

    return Timetable(
      id: id,
      courseCode: data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      subjectName: data['subjectName'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      faculty: data['faculty'] ?? '',
      room: data['room'] ?? '',
      days: List<String>.from(data['days'] ?? []),
      startTime: TimeOfDay(hour: start.hour, minute: start.minute),
      endTime: TimeOfDay(hour: end.hour, minute: end.minute),
      batch: data['batch'],
      section: data['section'],
      className: data['className'],
      classId: data['classId'],
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'faculty': faculty,
      'room': room,
      'days': days,
      'startTime': _timeToTimestamp(startTime),
      'endTime': _timeToTimestamp(endTime),
      if (batch != null) 'batch': batch,
      if (section != null) 'section': section,
      if (className != null) 'className': className,
      if (classId != null) 'classId': classId,
      'createdBy': createdBy,
    };
  }

  Timestamp _timeToTimestamp(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return Timestamp.fromDate(dt);
  }

  String get timeRange {
    final start = DateTime(2023, 1, 1, startTime.hour, startTime.minute);
    final end = DateTime(2023, 1, 1, endTime.hour, endTime.minute);
    return '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}';
  }

  bool isOnDay(String day) => days.contains(day);
}