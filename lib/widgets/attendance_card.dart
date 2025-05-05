import 'package:flutter/material.dart';
import 'package:iic_connect/models/attendance.dart';
import 'package:iic_connect/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';

class AttendanceCard extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AttendanceCard({
    super.key,
    required this.attendance,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canEditDelete = authProvider.user?.isAdmin == true ||
        authProvider.user?.id == attendance.facultyId;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            attendance.status == 'Present' ? Icons.check_circle : Icons.cancel,
            color: attendance.status == 'Present' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.studentName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${attendance.date.day}/${attendance.date.month}/${attendance.date.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  attendance.subjectName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (canEditDelete) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}