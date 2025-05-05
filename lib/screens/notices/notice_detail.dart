import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/notice.dart';
import 'package:iic_connect/providers/notice_provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:iic_connect/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeDetailScreen extends StatefulWidget {
  static const routeName = '/notice-detail';

  const NoticeDetailScreen({super.key});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  String? _noticeId;
  bool _isLoading = true;
  Notice? _notice;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_noticeId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _noticeId = args;
        _loadNoticeData();
      } else if (args is Notice) {
        _noticeId = args.id;
        _notice = args;
        _isLoading = false;
      }
    }
  }

  Future<void> _loadNoticeData() async {
    try {
      if (_noticeId != null) {
        final notice = await Provider.of<NoticeProvider>(context, listen: false)
            .fetchNoticeDetails(_noticeId!);
        if (mounted) {
          setState(() {
            _notice = notice;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading notice: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Details'),
        actions: [
          if (_notice != null &&
              (currentUser?.isAdmin == true ||
                  currentUser?.role == AppConstants.staffRole ||
                  _notice?.postedBy == currentUser?.id)) // Allow creator to delete
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNotice(context, _notice!.id),
            ),
          if (_notice?.attachmentUrl != null)
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () => _handleAttachmentClick(_notice!.attachmentUrl!),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(
              onPressed: _loadNoticeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _notice == null
          ? const Center(child: Text('Notice not found'))
          : _buildNoticeContent(_notice!),
    );
  }

  Widget _buildNoticeContent(Notice notice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notice.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text(
                  notice.category.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor:
                Theme.of(context).colorScheme.secondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Posted by ${notice.postedByName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassmorphismDecoration(context),
            child: Text(
              notice.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMMM dd, yyyy - hh:mm a').format(notice.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (notice.attachmentUrl != null) ...[
            const SizedBox(height: 16),
            Text(
              'Attachment:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _handleAttachmentClick(notice.attachmentUrl!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notice.attachmentUrl!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.download),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteNotice(BuildContext context, String noticeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<NoticeProvider>(context, listen: false)
            .deleteNotice(noticeId);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted successfully')),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete notice: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleAttachmentClick(String url) async {
    try {
      // For web, we don't need storage permissions
      if (!kIsWeb) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank', // For web - opens in new tab
        );
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open attachment: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}