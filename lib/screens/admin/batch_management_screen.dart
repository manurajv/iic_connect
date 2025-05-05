import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/academic_model.dart';
import 'package:iic_connect/providers/academic_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';

class BatchManagementScreen extends StatefulWidget {
  static const routeName = '/admin/batches';

  const BatchManagementScreen({super.key});

  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AcademicProvider>(context, listen: false).fetchBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final academicProvider = Provider.of<AcademicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => academicProvider.fetchBatches(),
          ),
        ],
      ),
      body: academicProvider.isLoading
          ? const LoadingIndicator()
          : _buildBatchList(academicProvider.batches),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBatchDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBatchList(List<Batch> batches) {
    return ListView.builder(
      itemCount: batches.length,
      itemBuilder: (context, index) {
        final batch = batches[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(batch.name),
            subtitle: Text('Created: ${batch.createdAt.toDate()}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteBatch(context, batch.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddBatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Batch'),
        content: TextField(
          controller: _nameController,
          decoration: AppTheme.inputDecoration(hint: 'Batch Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                try {
                  await Provider.of<AcademicProvider>(context, listen: false)
                      .addBatch(_nameController.text);
                  Navigator.of(ctx).pop();
                  _nameController.clear();
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteBatch(BuildContext context, String batchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this batch?'),
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

    if (confirmed == true) {
      try {
        await Provider.of<AcademicProvider>(context, listen: false)
            .deleteBatch(batchId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}