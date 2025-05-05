// create_notice_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/notice.dart';
import 'package:iic_connect/providers/notice_provider.dart';
import 'package:iic_connect/models/user.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CreateNoticeScreen extends StatefulWidget {
  static const routeName = '/create-notice';

  const CreateNoticeScreen({super.key});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'General';
  File? _attachment;
  String? _attachmentName;
  bool _isLoading = false;

  final List<String> _categories = [
    'General',
    'Academic',
    'Event',
    'Urgent'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _attachment = File(result.files.single.path!);
          _attachmentName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<String?> _uploadAttachment() async {
    if (_attachment == null) return null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Create user-specific folder for better organization
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('notice_attachments/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_attachmentName');

      // Show upload progress
      final uploadTask = storageRef.putFile(_attachment!);
      final snapshot = await uploadTask;

      // Get download URL with extended token lifespan
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Upload error: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
      return null;
    } catch (e) {
      debugPrint('General error: $e');
      return null;
    }
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload attachment first
      final attachmentUrl = await _uploadAttachment();

      // 2. Get current user with additional data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // 3. Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 4. Get the user's name (try displayName first, then Firestore, then default)
      String userName = userDoc.data()?['name'] ?? 'Admin';

      // 5. Create notice
      final newNotice = Notice(
        id: '', // Firestore will auto-generate
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        date: DateTime.now(),
        attachmentUrl: attachmentUrl,
        postedBy: user.uid,
        postedByName: userName, // Use the name we just fetched
      );

      // 6. Save to Firestore
      await Provider.of<NoticeProvider>(context, listen: false)
          .createNotice(newNotice);

      // 7. Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice published!')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Notice'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_attachment != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachment: $_attachmentName',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _attachment = null;
                          _attachmentName = null;
                        });
                      },
                    ),
                  ],
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Attachment'),
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submitNotice,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Publish Notice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}