import 'package:flutter/material.dart';
import 'package:iic_connect/models/project.dart';
import 'package:intl/intl.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(project.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: project.tags
                  .map((tag) => Chip(
                label: Text(tag),
                labelStyle: const TextStyle(fontSize: 12),
              ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    project.status.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(project.status),
                ),
                Text(
                  'Last updated: ${DateFormat('MMM dd, yyyy').format(project.updatedAt ?? project.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color? _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.withOpacity(0.2);
      case 'in progress':
        return Colors.blue.withOpacity(0.2);
      case 'pending':
        return Colors.orange.withOpacity(0.2);
      default:
        return null;
    }
  }
}