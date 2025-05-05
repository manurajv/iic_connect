import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/lab_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';
import 'package:iic_connect/widgets/lab_card.dart';

class LabsScreen extends StatelessWidget {
  const LabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Available Labs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        child: Padding(
          padding: const EdgeInsets.only(top: kToolbarHeight + 20),
          child: Consumer<LabProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (provider.labs.isEmpty) {
                return Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No labs available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.labs.length,
                itemBuilder: (ctx, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: LabCard(lab: provider.labs[index]),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(28),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}