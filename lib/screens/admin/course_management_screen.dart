// lib/screens/admin/course_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/academic_provider.dart';

import '../../models/academic_model.dart';

class CourseManagementScreen extends StatelessWidget {
  static const routeName = '/course-management';

  const CourseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
      ),
      body: FutureBuilder(
        future: academicProvider.fetchCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Consumer<AcademicProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                itemCount: provider.courses.length,
                itemBuilder: (context, index) {
                  final course = provider.courses[index];
                  return ListTile(
                    title: Text(course.name),
                    subtitle: Text('Code: ${course.code}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditCourseDialog(context, course),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => provider.deleteCourse(course.id),
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
        onPressed: () => _showAddCourseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Course Code'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                academicProvider.addCourse(
                  nameController.text.trim(),
                  codeController.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCourseDialog(BuildContext context, Course course) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
    final nameController = TextEditingController(text: course.name);
    final codeController = TextEditingController(text: course.code);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Course Code'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                academicProvider.updateCourse(
                  course.id,
                  nameController.text.trim(),
                  codeController.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}