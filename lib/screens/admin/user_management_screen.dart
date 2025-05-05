import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/screens/auth/register_screen.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';

import '../../models/user.dart';
import '../../providers/subject_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';

class UserManagementScreen extends StatefulWidget {
  static const routeName = '/admin/users';

  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  String? _selectedRoleFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch users when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    // Filter users based on search and role filter
    final filteredUsers = authProvider.allUsers.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.enrollmentNumber != null &&
              user.enrollmentNumber!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesRole = _selectedRoleFilter == null ||
          user.role.toLowerCase() == _selectedRoleFilter!.toLowerCase();

      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await authProvider.fetchAllUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error refreshing: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const RegisterScreen(isAdminCreating: true),
                ),
              ),
            ),
        ],
      ),
      body: authProvider.isLoading
          ? const LoadingIndicator()
          : Column(
        children: [
          // Search and filter bar
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: AppTheme.inputDecoration(
                    label: 'Search users',
                    prefixIcon: Icons.search,
                  ).copyWith(
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(null, 'All'),
                      _buildFilterChip(AppConstants.studentRole, 'Students'),
                      _buildFilterChip(AppConstants.facultyRole, 'Faculty'),
                      _buildFilterChip(AppConstants.staffRole, 'Staff'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: _buildUserList(filteredUsers, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? role, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedRoleFilter == role,
        onSelected: (selected) {
          setState(() => _selectedRoleFilter = selected ? role : null);
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: _selectedRoleFilter == role
              ? Theme.of(context).primaryColor
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildUserList(List<User> users, bool isAdmin) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(user.name[0]),
            ),
            title: Text(
              user.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                if (user.enrollmentNumber != null)
                  Text('Enrollment: ${user.enrollmentNumber}'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(user.role),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor,
                        fontSize: 12,
                      ),
                    ),
                    if (user.batch != null && user.role == AppConstants.studentRole)
                      Chip(
                        label: Text(user.batch!),
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: isAdmin
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.role == AppConstants.facultyRole)
                  IconButton(
                    icon: const Icon(Icons.school),
                    color: Theme.of(context).colorScheme.secondary,
                    onPressed: () => _assignAsFaculty(context, user),
                    tooltip: 'Assign to Subject',
                  ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => RegisterScreen(
                        userToEdit: user,
                        isAdminEditing: true,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _confirmDeleteUser(context, user),
                ),
              ],
            )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm Delete',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text('Are you sure you want to delete ${user.name}?'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    GlassButton(
                      text: 'Delete',
                      onPressed: () => Navigator.of(ctx).pop(true),
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} deleted successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _assignAsFaculty(BuildContext context, User user) async {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    await subjectProvider.loadAllSubjects();

    final unassignedSubjects = subjectProvider.subjects
        .where((subject) => subject['facultyId'] == null)
        .toList();

    if (unassignedSubjects.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unassigned subjects available')),
      );
      return;
    }

    final selectedSubject = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign to Subject'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unassignedSubjects.length,
            itemBuilder: (ctx, index) {
              final subject = unassignedSubjects[index];
              return ListTile(
                title: Text(subject['name']),
                subtitle: Text('${subject['code']} - ${subject['batchId']}'),
                onTap: () => Navigator.of(ctx).pop(subject),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedSubject != null) {
      try {
        await subjectProvider.assignFacultyToSubject(
          selectedSubject['id'],
          user.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned ${user.name} to ${selectedSubject['name']}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}