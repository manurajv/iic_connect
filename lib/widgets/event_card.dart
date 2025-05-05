import 'package:flutter/material.dart';
import 'package:iic_connect/models/event.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final String userId;
  final VoidCallback? onRegister;

  const EventCard({
    super.key,
    required this.event,
    required this.userId,
    this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final isRegistered = event.registeredParticipants.contains(userId);
    final spotsLeft = event.maxParticipants - event.registeredParticipants.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(event.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(DateFormat('MMM dd, yyyy').format(event.startTime)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(event.location),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(event.category),
                ),
                Text(
                  spotsLeft > 0 ? '$spotsLeft spots left' : 'Fully booked',
                  style: TextStyle(
                    color: spotsLeft > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isRegistered || spotsLeft <= 0 ? null : onRegister,
              child: Text(
                isRegistered ? 'Registered' : 'Register Now',
              ),
            ),
          ],
        ),
      ),
    );
  }
}