import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/academic_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/constants.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_button.dart';
import 'package:iic_connect/widgets/glass_card.dart';

import '../../models/user.dart';
import '../../utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  final User? userToEdit;
  final bool isAdminCreating;
  final bool isAdminEditing;

  const RegisterScreen({
    super.key,
    this.userToEdit,
    this.isAdminCreating = false,
    this.isAdminEditing = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = AppConstants.studentRole;
  String? _selectedBatch;
  String? _selectedClass;
  String? _selectedCourse;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _dataLoaded = false;
  bool _isAdminFlow = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (widget.userToEdit != null) {
      _nameController.text = widget.userToEdit!.name;
      _emailController.text = widget.userToEdit!.email;
      _selectedRole = widget.userToEdit!.role;
      _selectedCourse = widget.userToEdit!.course;
      _selectedBatch = widget.userToEdit!.batch;
      _selectedClass = widget.userToEdit!.classId;
      _enrollmentController.text = widget.userToEdit!.enrollmentNumber ?? '';
      _phoneController.text = widget.userToEdit!.phone ?? '';
      _isAdmin = widget.userToEdit!.isAdmin ?? false;
    }
    // Only allow admin role selection if current user is admin
    _isAdminFlow = authProvider.isAdmin &&
        (widget.isAdminCreating || widget.isAdminEditing);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
      await Future.wait([
        academicProvider.fetchBatches(),
        academicProvider.fetchClasses(),
        academicProvider.fetchCourses(),
      ]);

      // If editing a user, find matching academic data
      if (widget.userToEdit != null) {
        final courses = academicProvider.courses;
        final batches = academicProvider.batches;
        final classes = academicProvider.classes;

        // Find matching course if it exists
        if (widget.userToEdit!.course != null) {
          final matchingCourse = courses.firstWhere(
                (course) => course.name == widget.userToEdit!.course,
            orElse: () => courses.first,
          );
          _selectedCourse = matchingCourse.id;
        }

        // Find matching batch if it exists
        if (widget.userToEdit!.batch != null) {
          final matchingBatch = batches.firstWhere(
                (batch) => batch.name == widget.userToEdit!.batch,
            orElse: () => batches.firstWhere(
                  (batch) => batch.id == _selectedBatch,
              orElse: () => batches.first,
            ),
          );
          _selectedBatch = matchingBatch.id;
        }

        // Find matching class if it exists
        if (widget.userToEdit!.classId != null) {
          final matchingClass = classes.firstWhere(
                (classItem) => classItem.id == widget.userToEdit!.classId,
            orElse: () => classes.firstWhere(
                  (classItem) => classItem.name == widget.userToEdit!.classId,
              orElse: () => classes.first,
            ),
          );
          _selectedClass = matchingClass.id;
        }
      }

      setState(() => _dataLoaded = true);
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load academic data: ${e.toString()}');
      }
    }
  }

  Future<void> _registerOrUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == AppConstants.studentRole &&
        (_selectedCourse == null || _selectedBatch == null || _selectedClass == null)) {
      showErrorSnackbar(context, 'Please select course, batch and class');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'enrollmentNumber': _enrollmentController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': 'IIC',
        'isAdmin': _isAdmin,
        if (_selectedRole == AppConstants.studentRole && _selectedCourse != null)
          'course': academicProvider.courses
              .firstWhere((course) => course.id == _selectedCourse)
              .name,
        if (_selectedRole == AppConstants.studentRole && _selectedBatch != null)
          'batch': academicProvider.batches
              .firstWhere((batch) => batch.id == _selectedBatch)
              .name,
        if (_selectedRole == AppConstants.studentRole && _selectedClass != null)
          'classId': _selectedClass,
      };

      if (widget.userToEdit == null) {
        await authProvider.register({
          ...userData,
          'password': _passwordController.text.trim(),
        });
        showSuccessSnackbar(context, 'User registered successfully');
      } else {
        await authProvider.updateUser(widget.userToEdit!.id, userData);
        showSuccessSnackbar(context, 'User updated successfully');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Operation failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context);
    final isAdminFlow = widget.isAdminCreating || widget.isAdminEditing;

    if (!_dataLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userToEdit == null ? 'Register' : 'Edit User'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Full Name',
                            prefixIcon: Icons.person,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Email',
                            prefixIcon: Icons.email,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          enabled: widget.userToEdit == null,
                        ),
                        if (widget.userToEdit == null) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: AppTheme.inputDecoration(
                              label: 'Password',
                              prefixIcon: Icons.lock,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: AppTheme.inputDecoration(
                              label: 'Confirm Password',
                              prefixIcon: Icons.lock,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                'Select Role',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildRoleChip(AppConstants.studentRole),
                                  _buildRoleChip(AppConstants.facultyRole),
                                  _buildRoleChip(AppConstants.staffRole),
                                  if (isAdminFlow)
                                    _buildRoleChip(AppConstants.adminRole),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isAdminFlow) ...[
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Admin Privileges'),
                            value: _isAdmin,
                            onChanged: (value) => setState(() => _isAdmin = value),
                          ),
                        ],
                        if (_selectedRole == AppConstants.studentRole) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCourse,
                            decoration: AppTheme.inputDecoration(
                              label: 'Select Course',
                              prefixIcon: Icons.school,
                            ),
                            items: academicProvider.courses.map((course) {
                              return DropdownMenuItem(
                                value: course.id,
                                child: Text(course.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCourse = value;
                                _selectedBatch = null;
                                _selectedClass = null;
                              });
                            },
                            validator: (value) {
                              if (_selectedRole == AppConstants.studentRole && value == null) {
                                return 'Please select your course';
                              }
                              return null;
                            },
                          ),

                          if (_selectedCourse != null) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedBatch,
                              decoration: AppTheme.inputDecoration(
                                label: 'Select Batch',
                                prefixIcon: Icons.group,
                              ),
                              items: academicProvider.batches.map((batch) {
                                return DropdownMenuItem(
                                  value: batch.id,
                                  child: Text(batch.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBatch = value;
                                  _selectedClass = null;
                                });
                              },
                              validator: (value) {
                                if (_selectedRole == AppConstants.studentRole && value == null) {
                                  return 'Please select your batch';
                                }
                                return null;
                              },
                            ),
                          ],

                          if (_selectedBatch != null) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedClass,
                              decoration: AppTheme.inputDecoration(
                                label: 'Select Class',
                                prefixIcon: Icons.class_,
                              ),
                              items: academicProvider.classes
                                  .where((c) => c.batchId == _selectedBatch)
                                  .map((classItem) {
                                return DropdownMenuItem(
                                  value: classItem.id,
                                  child: Text(classItem.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedClass = value);
                              },
                              validator: (value) {
                                if (_selectedRole == AppConstants.studentRole && value == null) {
                                  return 'Please select your class';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),
                        if (_selectedRole == AppConstants.studentRole)
                          TextFormField(
                            controller: _enrollmentController,
                            decoration: AppTheme.inputDecoration(
                              label: 'Enrollment Number',
                              prefixIcon: Icons.numbers,
                            ),
                            validator: (value) {
                              if (_selectedRole == AppConstants.studentRole &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter enrollment number';
                              }
                              return null;
                            },
                          ),
                        if (_selectedRole == AppConstants.facultyRole)
                          TextFormField(
                            controller: _enrollmentController,
                            decoration: AppTheme.inputDecoration(
                              label: 'Faculty Number',
                              prefixIcon: Icons.numbers,
                            ),
                            validator: (value) {
                              if (_selectedRole == AppConstants.facultyRole &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter faculty number';
                              }
                              return null;
                            },
                          ),
                        if (_selectedRole == AppConstants.staffRole)
                          TextFormField(
                            controller: _enrollmentController,
                            decoration: AppTheme.inputDecoration(
                              label: 'Employee Number',
                              prefixIcon: Icons.numbers,
                            ),
                            validator: (value) {
                              if (_selectedRole == AppConstants.staffRole &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter employee number';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Phone Number',
                            prefixIcon: Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                              return 'Please enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        GlassButton(
                          text: widget.userToEdit == null ? 'Register' : 'Update',
                          onPressed: () {
                            if (!_isLoading) {
                              _registerOrUpdate();
                            }
                          },
                          icon: widget.userToEdit == null
                              ? Icons.person_add
                              : Icons.save,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    return ChoiceChip(
      label: Text(role),
      selected: _selectedRole == role,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRole = role);
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _enrollmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}