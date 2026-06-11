import 'package:flutter/material.dart';

/// A generic paginated list view that loads items in batches.
/// Loads [pageSize] items at a time and fetches more when near bottom.
class PaginatedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) fetchItems;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? header;
  final Widget? emptyWidget;
  final int pageSize;
  final double loadThreshold;
  final EdgeInsetsGeometry? padding;

  const PaginatedListView({
    super.key,
    required this.fetchItems,
    required this.itemBuilder,
    this.header,
    this.emptyWidget,
    this.pageSize = 20,
    this.loadThreshold = 200.0,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - widget.loadThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems =
          await widget.fetchItems(_items.length, widget.pageSize);

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length >= widget.pageSize;
          _isLoading = false;
          _initialLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(child: Text('Tidak ada data'));
    }

    final itemCount =
        _items.length + (_hasMore ? 1 : 0) + (widget.header != null ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding ?? const EdgeInsets.all(0),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (widget.header != null && index == 0) {
            return widget.header!;
          }

          final adjustedIndex =
              widget.header != null ? index - 1 : index;

          if (adjustedIndex >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Memuat lebih banyak...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return widget.itemBuilder(context, _items[adjustedIndex], adjustedIndex);
        },
      ),
    );
  }
}
