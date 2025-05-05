import 'package:flutter/material.dart';
import 'package:iic_connect/models/attendance.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';

class AttendanceCard extends StatelessWidget {
  final Attendance attendance;

  const AttendanceCard({
    super.key,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
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
                  attendance.subjectName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${attendance.date.day}/${attendance.date.month}/${attendance.date.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (attendance.studentName.isNotEmpty)
                  Text(
                    attendance.studentName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}