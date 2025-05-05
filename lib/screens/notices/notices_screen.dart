import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/models/notice.dart';
import 'package:iic_connect/providers/notice_provider.dart';
import 'package:iic_connect/widgets/notice_card.dart';
import 'package:iic_connect/screens/notices/notice_detail.dart';
import 'package:iic_connect/widgets/loading_indicator.dart';

class NoticesScreen extends StatefulWidget {
  final bool showFullScreenButton;

  const NoticesScreen({
    super.key,
    this.showFullScreenButton = false
  });

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotices());
  }

  Future<void> _loadNotices() async {
    await Provider.of<NoticeProvider>(context, listen: false).fetchNotices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noticeProvider = Provider.of<NoticeProvider>(context);
    final notices = _filterNotices(noticeProvider.notices);

    if (widget.showFullScreenButton) {
      return Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          if (noticeProvider.isLoading) const Expanded(child: LoadingIndicator()),
          if (noticeProvider.error != null)
            Center(
              child: Text(noticeProvider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (!noticeProvider.isLoading && noticeProvider.error == null)
            Expanded(
              child: notices.isEmpty
                  ? const Center(child: Text('No notices found'))
                  : ListView.builder(
                itemCount: notices.length > 3 ? 3 : notices.length,
                itemBuilder: (ctx, index) {
                  final notice = notices[index];
                  return NoticeCard(
                    notice: notice,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoticeDetailScreen(),
                        settings: RouteSettings(arguments: notice.id), // Pass the notice ID
                      ),
                    ),
                  );
                },
              ),
            ),
          if (notices.length > 3)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('All Notices')),
                    body: const FullScreenNoticesScreen(),
                  ),
                ),
              ),
              child: const Text('View All Notices'),
            ),
        ],
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Department Notices'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNotices,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryFilter(),
            if (noticeProvider.isLoading) const Expanded(child: LoadingIndicator()),
            if (noticeProvider.error != null)
              Expanded(
                child: Center(
                  child: Text(noticeProvider.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ),
            if (!noticeProvider.isLoading && noticeProvider.error == null)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadNotices,
                  child: notices.isEmpty
                      ? const Center(child: Text('No notices found'))
                      : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: notices.length,
                    itemBuilder: (ctx, index) {
                      final notice = notices[index];
                      return NoticeCard(
                        notice: notice,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            NoticeDetailScreen.routeName,
                            arguments: notice.id, // Pass the notice ID
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search notices...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'General', 'Academic', 'Event', 'Urgent'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                });
              },
            ),
          );
        },
      ),
    );
  }

  List<Notice> _filterNotices(List<Notice> notices) {
    return notices.where((notice) {
      final matchesSearch = notice.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          notice.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          notice.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }
}

class FullScreenNoticesScreen extends StatelessWidget {
  const FullScreenNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NoticesScreen();
  }
}