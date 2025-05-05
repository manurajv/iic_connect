// lib/screens/admin/class_management_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/academic_provider.dart';

import '../../models/academic_model.dart';

class ClassManagementScreen extends StatelessWidget {
  static const routeName = '/class-management';

  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Management'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          academicProvider.fetchBatches(),
          academicProvider.fetchClasses(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Consumer<AcademicProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                itemCount: provider.classes.length,
                itemBuilder: (context, index) {
                  final classItem = provider.classes[index];
                  final batch = provider.batches.firstWhere(
                        (b) => b.id == classItem.batchId,
                    orElse: () => Batch(id: '', name: 'Unknown', createdAt: Timestamp.now()),
                  );
                  return ListTile(
                    title: Text(classItem.name),
                    subtitle: Text('Batch: ${batch.name}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditClassDialog(context, classItem, provider.batches),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => provider.deleteClass(classItem.id),
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
        onPressed: () => _showAddClassDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
    final nameController = TextEditingController();
    String? selectedBatchId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Class'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Class Name'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBatchId,
                    hint: const Text('Select Batch'),
                    items: academicProvider.batches.map((batch) {
                      return DropdownMenuItem(
                        value: batch.id,
                        child: Text(batch.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBatchId = value;
                      });
                    },
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
                    if (selectedBatchId != null) {
                      academicProvider.addClass(
                        nameController.text.trim(),
                        selectedBatchId!,
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

  void _showEditClassDialog(BuildContext context, Class classItem, List<Batch> batches) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
    final nameController = TextEditingController(text: classItem.name);
    String? selectedBatchId = classItem.batchId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Class'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Class Name'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBatchId,
                    items: batches.map((batch) {
                      return DropdownMenuItem(
                        value: batch.id,
                        child: Text(batch.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBatchId = value;
                      });
                    },
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
                    academicProvider.updateClass(
                      classItem.id,
                      nameController.text.trim(),
                      selectedBatchId!,
                    );
                    Navigator.pop(context);
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