import 'package:flutter/material.dart';
import 'package:iic_connect/models/lab.dart';
import 'package:intl/intl.dart';

class LabCard extends StatelessWidget {
  final Lab lab;

  const LabCard({super.key, required this.lab});

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
              lab.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Location: ${lab.location}'),
            Text('Capacity: ${lab.capacity}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: lab.equipment
                  .map((equip) => Chip(
                label: Text(equip),
                labelStyle: const TextStyle(fontSize: 12),
              ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (lab.bookings.isNotEmpty) ...[
              const Text(
                'Upcoming Bookings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...lab.bookings.map((booking) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(booking.purpose),
                subtitle: Text(
                  '${DateFormat('MMM dd, yyyy').format(booking.startTime)} - '
                      '${DateFormat.jm().format(booking.startTime)} to '
                      '${DateFormat.jm().format(booking.endTime)}',
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}