import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/event.dart';
import 'package:iic_connect/providers/event_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';

class EventRegistrationScreen extends StatelessWidget {
  final Event event;

  const EventRegistrationScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final eventProvider = Provider.of<EventProvider>(context);
    final isRegistered = event.registeredParticipants.contains(user?.id);

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Event Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('MMM dd, yyyy').format(event.startTime)),
              subtitle: Text(
                '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(event.location),
            ),
            const Spacer(),
            if (isRegistered)
              const Text(
                'You are already registered for this event',
                style: TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              )
            else if (event.registeredParticipants.length >= event.maxParticipants)
              const Text(
                'This event is fully booked',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await eventProvider.registerForEvent(event.id, user!.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully registered for event'),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Register Now'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}