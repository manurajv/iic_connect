import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/user.dart';
import 'package:iic_connect/providers/event_provider.dart';
import 'package:iic_connect/widgets/event_card.dart';

import '../../providers/auth_provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.events.length,
            itemBuilder: (ctx, index) {
              return EventCard(
                event: provider.events[index],
                userId: user?.id ?? '',
              );
            },
          );
        },
      ),
    );
  }
}