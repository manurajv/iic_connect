import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/timetable.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/providers/timetable_provider.dart';
import 'package:iic_connect/utils/constants.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';
import 'package:iic_connect/widgets/timetable_card.dart';

import '../../models/user.dart';
import '../../providers/academic_provider.dart';

class TimetableScreen extends StatefulWidget {
  static const routeName = '/timetable';

  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  String _selectedDay = 'Monday';
  String? _selectedClassFilter;
  String? _selectedFacultyFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimetable();
      _loadAcademicData(); // Add this line
    });
  }

  Future<void> _loadTimetable() async {
    final authProvider = context.read<AuthProvider>();
    final timetableProvider = context.read<TimetableProvider>();
    final user = authProvider.user;

    if (user == null) return;

    try {
      if (user.role == AppConstants.facultyRole) {
        await timetableProvider.fetchTimetable(userId: user.id);
      } else {
        if (user.batch == null || user.batch!.isEmpty) {
          throw Exception('Student batch information missing');
        }
        await timetableProvider.fetchTimetable(batch: user.batch);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timetable: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadAcademicData() async {
    try {
      await context.read<AcademicProvider>().fetchClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading academic data: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildDaySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(day),
              selected: _selectedDay == day,
              onSelected: (selected) {
                setState(() {
                  _selectedDay = day;
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedDay == day
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdminFilters(AcademicProvider academicProvider) {
    // Show loading indicator if classes are being fetched
    if (academicProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message if there was an error
    // if (academicProvider.error != null) {
    //   return Text('Error: ${academicProvider.error}');
    // }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedClassFilter,
            decoration: AppTheme.inputDecoration(
              label: 'Filter by Class',
              prefixIcon: Icons.group,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Classes')),
              ...academicProvider.classes.map((classItem) {
                return DropdownMenuItem(
                  value: classItem.id,
                  child: Text(classItem.name),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedClassFilter = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedFacultyFilter,
            decoration: AppTheme.inputDecoration(
              label: 'Filter by Faculty',
              prefixIcon: Icons.person,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Faculty')),
              ..._getUniqueFacultyNames().map((faculty) {
                return DropdownMenuItem(
                  value: faculty,
                  child: Text(faculty),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFacultyFilter = value;
              });
            },
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueFacultyNames() {
    final timetableProvider = context.read<TimetableProvider>();
    final facultyNames = timetableProvider.timetables
        .map((t) => t.faculty)
        .toSet()
        .toList();
    facultyNames.sort();
    return facultyNames;
  }

  Widget _buildTimetableList(List<Timetable> timetables, User? user, bool isAdmin) {
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);

    // Apply filters
    var filteredClasses = timetables.where((item) => item.isOnDay(_selectedDay)).toList();

    // Filter by class if selected
    if (_selectedClassFilter != null) {
      filteredClasses = filteredClasses.where((item) {
        if (item.classId != null) {
          return item.classId == _selectedClassFilter;
        }
        if (item.className != null) {
          try {
            final classItem = academicProvider.classes.firstWhere(
                  (c) => c.name == item.className,
            );
            return classItem.id == _selectedClassFilter;
          } catch (e) {
            return false;
          }
        }
        return false;
      }).toList();
    }

    if (_selectedFacultyFilter != null) {
      filteredClasses = filteredClasses.where((item) => item.faculty == _selectedFacultyFilter).toList();
    }

    if (filteredClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No classes scheduled for $_selectedDay',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (user?.role == AppConstants.studentRole &&
                (user?.batch == null || user!.batch!.isEmpty))
              Text(
                'Please contact admin to update your batch information',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimetable,
      child: ListView.builder(
        itemCount: filteredClasses.length,
        itemBuilder: (context, index) {
          final canDelete = isAdmin ||
              (user?.role == AppConstants.facultyRole &&
                  user?.id == filteredClasses[index].createdBy);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TimetableCard(
              timetable: filteredClasses[index],
              onDelete: canDelete
                  ? () => _deleteTimetable(filteredClasses[index].id)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTimetable(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this timetable entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<TimetableProvider>().deleteTimetable(id);
        await _loadTimetable();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timetable entry deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final timetableProvider = context.watch<TimetableProvider>();
    final user = authProvider.user;
    final academicProvider = context.watch<AcademicProvider>();
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.role == AppConstants.facultyRole
            ? 'My Timetable'
            : 'Class Timetable'),
      ),
      body: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (user?.role == AppConstants.studentRole)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Batch: ${user?.batch ?? 'N/A'} | Section: ${user?.section ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            _buildDaySelector(),
            if (isAdmin || user?.role == AppConstants.staffRole)
              _buildAdminFilters(academicProvider),
            const SizedBox(height: 16),
            Expanded(
              child: timetableProvider.isLoading
                  ? const LoadingIndicator()
                  : timetableProvider.error != null
                  ? Center(child: Text(timetableProvider.error!))
                  : _buildTimetableList(timetableProvider.timetables, user, isAdmin),
            ),
          ],
        ),
      ),
    );
  }
}