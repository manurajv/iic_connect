import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/academic_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';

import '../../models/academic_model.dart';
import '../../models/user.dart';

class SubjectManagementScreen extends StatelessWidget {
  static const routeName = '/subject-management';

  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Management'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          academicProvider.fetchBatches(),
          academicProvider.fetchClasses(),
          academicProvider.fetchSubjects(),
          authProvider.fetchAllUsers(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Consumer2<AcademicProvider, AuthProvider>(
            builder: (context, academicProvider, authProvider, child) {
              return ListView.builder(
                itemCount: academicProvider.subjects.length,
                itemBuilder: (context, index) {
                  final subject = academicProvider.subjects[index];
                  final batch = academicProvider.batches.firstWhere(
                        (b) => b.id == subject.batchId,
                    orElse: () => Batch(id: '', name: 'Unknown', createdAt: Timestamp.now()),
                  );
                  final classItem = academicProvider.classes.firstWhere(
                        (c) => c.id == subject.classId,
                    orElse: () => Class(id: '', name: 'Unknown', batchId: '', createdAt: Timestamp.now()),
                  );
                  final faculty = authProvider.allUsers.firstWhere(
                        (u) => u.id == subject.facultyId,
                    orElse: () => User(
                      id: '',
                      name: 'Unassigned',
                      email: '',
                      role: '',
                      enrollmentNumber: null,
                      department: null,
                      phone: null,
                      profileImage: null,
                      createdAt: null,
                      batch: null,
                      section: null,
                      course: null,
                      classId: null,
                      isAdmin: false,
                    ),
                  );

                  return ListTile(
                    title: Text(subject.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code: ${subject.code}'),
                        Text('Batch: ${batch.name}'),
                        Text('Class: ${classItem.name}'),
                        Text('Faculty: ${faculty.name}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditSubjectDialog(
                            context,
                            subject,
                            academicProvider.batches,
                            academicProvider.classes,
                            authProvider.allUsers.where((u) => u.role == 'faculty').toList(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => academicProvider.deleteSubject(subject.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final nameController = TextEditingController();
    final codeController = TextEditingController();
    String? selectedBatchId;
    String? selectedClassId;
    String? selectedFacultyId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final availableClasses = selectedBatchId != null
                ? academicProvider.classes.where((c) => c.batchId == selectedBatchId).toList()
                : [];

            final facultyUsers = authProvider.allUsers.where((u) => u.role == 'faculty').toList();

            return AlertDialog(
              title: const Text('Add New Subject'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Subject Name'),
                    ),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Subject Code'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBatchId,
                      hint: const Text('Select Batch'),
                      items: academicProvider.batches.map<DropdownMenuItem<String>>((batch) {
                        return DropdownMenuItem<String>(
                          value: batch.id,
                          child: Text(batch.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedBatchId = value;
                          selectedClassId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedClassId,
                      hint: const Text('Select Class'),
                      items: availableClasses.map<DropdownMenuItem<String>>((classItem) {
                        return DropdownMenuItem<String>(
                          value: classItem.id,
                          child: Text(classItem.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedClassId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFacultyId,
                      hint: const Text('Select Faculty'),
                      items: facultyUsers.map<DropdownMenuItem<String>>((user) {
                        return DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedFacultyId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedBatchId != null &&
                        selectedClassId != null &&
                        selectedFacultyId != null) {
                      academicProvider.addSubject(
                        nameController.text.trim(),
                        codeController.text.trim(),
                        selectedBatchId!,
                        selectedClassId!,
                        selectedFacultyId!,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSubjectDialog(
      BuildContext context,
      Subject subject,
      List<Batch> batches,
      List<Class> classes,
      List<User> facultyUsers,
      ) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);

    final nameController = TextEditingController(text: subject.name);
    final codeController = TextEditingController(text: subject.code);
    String? selectedBatchId = subject.batchId;
    String? selectedClassId = subject.classId;
    String? selectedFacultyId = subject.facultyId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final availableClasses = selectedBatchId != null
                ? classes.where((c) => c.batchId == selectedBatchId).toList()
                : [];

            return AlertDialog(
              title: const Text('Edit Subject'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Subject Name'),
                    ),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Subject Code'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBatchId,
                      hint: const Text('Select Batch'),
                      items: batches.map<DropdownMenuItem<String>>((batch) {
                        return DropdownMenuItem<String>(
                          value: batch.id,
                          child: Text(batch.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedBatchId = value;
                          selectedClassId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedClassId,
                      hint: const Text('Select Class'),
                      items: availableClasses.map<DropdownMenuItem<String>>((classItem) {
                        return DropdownMenuItem<String>(
                          value: classItem.id,
                          child: Text(classItem.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedClassId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFacultyId,
                      hint: const Text('Select Faculty'),
                      items: facultyUsers.map<DropdownMenuItem<String>>((user) {
                        return DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedFacultyId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedBatchId != null &&
                        selectedClassId != null &&
                        selectedFacultyId != null) {
                      academicProvider.updateSubject(
                        subject.id,
                        nameController.text.trim(),
                        codeController.text.trim(),
                        selectedBatchId!,
                        selectedClassId!,
                        selectedFacultyId!,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}