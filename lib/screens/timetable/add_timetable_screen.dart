import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/timetable.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/providers/timetable_provider.dart';
import 'package:iic_connect/providers/academic_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';
import 'package:iic_connect/widgets/glass_card.dart';

class AddTimetableScreen extends StatefulWidget {
  static const routeName = '/add-timetable';

  const AddTimetableScreen({super.key});

  @override
  State<AddTimetableScreen> createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _roomController = TextEditingController();

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  final List<String> _selectedDays = [];

  String? _selectedFaculty;
  String? _selectedBatch;
  String? _selectedCourse;
  String? _selectedClass;
  String? _selectedSubjectCode;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
      await Future.wait([
        academicProvider.fetchFacultyMembers(),
        academicProvider.fetchBatches(),
        academicProvider.fetchCourses(),
        academicProvider.fetchClasses(),
        academicProvider.fetchSubjects(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);

    // Get the selected subject
    final selectedSubject = academicProvider.subjects.firstWhere(
          (subject) => subject.id == _selectedSubjectCode,
      orElse: () {
        throw Exception('Selected subject not found');
      },
    );

    // Get other selected values
    final selectedBatch = academicProvider.batches.firstWhere(
          (batch) => batch.id == _selectedBatch,
    );

    final selectedCourse = academicProvider.courses.firstWhere(
          (course) => course.id == _selectedCourse,
    );

    final selectedClass = academicProvider.classes.firstWhere(
          (classItem) => classItem.id == _selectedClass,
    );

    final newTimetable = Timetable(
      id: '',
      courseCode: selectedSubject.code, // Using subject code
      courseName: selectedSubject.name, // Using subject name
      subjectName: selectedSubject.name,
      subjectCode: selectedSubject.code,
      faculty: _selectedFaculty ?? '',
      room: _roomController.text,
      days: _selectedDays,
      startTime: _startTime,
      endTime: _endTime,
      batch: selectedBatch.name,
      className: selectedClass.name,
      classId: selectedClass.id,
      createdBy: authProvider.user!.id,
    );

    try {
      await timetableProvider.addTimetable(newTimetable);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add timetable: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final academicProvider = Provider.of<AcademicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Timetable Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Faculty Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFaculty,
                decoration: AppTheme.inputDecoration(label: 'Faculty Name'),
                items: academicProvider.facultyMembers.map((faculty) {
                  return DropdownMenuItem(
                    value: faculty.name,
                    child: Text(faculty.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFaculty = value;
                  });
                },
                validator: (value) => value == null ? 'Please select faculty' : null,
              ),
              const SizedBox(height: 16),

              // 2. Batch Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBatch,
                decoration: AppTheme.inputDecoration(label: 'Batch'),
                items: academicProvider.batches.map((batch) {
                  return DropdownMenuItem(
                    value: batch.id,
                    child: Text(batch.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBatch = value;
                    _selectedCourse = null;
                    _selectedClass = null;
                    _selectedSubjectCode = null;
                    _subjectNameController.clear();
                  });
                },
                validator: (value) => value == null ? 'Please select batch' : null,
              ),
              const SizedBox(height: 16),

              // 3. Course Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCourse,
                decoration: AppTheme.inputDecoration(label: 'Course'),
                items: _selectedBatch == null
                    ? []
                    : academicProvider.courses.map((course) {
                  return DropdownMenuItem(
                    value: course.id,
                    child: Text(course.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourse = value;
                    _selectedClass = null;
                    _selectedSubjectCode = null;
                    _subjectNameController.clear();
                  });
                },
                validator: (value) => value == null ? 'Please select course' : null,
              ),
              const SizedBox(height: 16),

              // 4. Class Dropdown
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: AppTheme.inputDecoration(label: 'Class'),
                items: _selectedBatch == null
                    ? []
                    : academicProvider.classes
                    .where((classItem) => classItem.batchId == _selectedBatch)
                    .map((classItem) {
                  return DropdownMenuItem(
                    value: classItem.id,
                    child: Text(classItem.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                    _selectedSubjectCode = null;
                    _subjectNameController.clear();
                  });
                },
                validator: (value) => value == null ? 'Please select class' : null,
              ),
              const SizedBox(height: 16),

              // 5. Subject Code Dropdown
              // 5. Subject Code Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSubjectCode,
                decoration: AppTheme.inputDecoration(label: 'Subject Code'),
                items: _selectedClass == null
                    ? []
                    : academicProvider.subjects
                    .where((subject) => subject.classId == _selectedClass)
                    .map((subject) {
                  print('Available Subject: ${subject.code} - ${subject.name}');
                  return DropdownMenuItem(
                    value: subject.id,
                    child: Text(subject.code),
                    onTap: () {
                      _subjectNameController.text = subject.name;
                    },
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectCode = value;
                  });
                },
                validator: (value) => value == null ? 'Please select subject code' : null,
              ),
              const SizedBox(height: 16),

              // 6. Subject Name (auto-filled)
              TextFormField(
                controller: _subjectNameController,
                decoration: AppTheme.inputDecoration(label: 'Subject Name'),
                readOnly: true,
                validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              // 7. Room (text input)
              TextFormField(
                controller: _roomController,
                decoration: AppTheme.inputDecoration(label: 'Room Number'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter room number' : null,
              ),
              const SizedBox(height: 24),

              // Days Selection
              Text(
                'Select Days:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _days.map((day) {
                  return FilterChip(
                    label: Text(day),
                    selected: _selectedDays.contains(day),
                    onSelected: (_) => _toggleDay(day),
                    selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Time',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _startTime.format(context),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Time',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _endTime.format(context),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submitForm,
                  child: authProvider.isLoading
                      ? const LoadingIndicator()
                      : const Text('Add Timetable Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}