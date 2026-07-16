import 'package:flutter/material.dart';

/// Renders [items] page-by-page.
///
/// Two modes:
/// - default (`shrinkWrap == false`): owns its scroll area (needs a bounded
///   height, e.g. inside an [Expanded]) and reveals the next page as the user
///   scrolls near the bottom — infinite-scroll UX.
/// - `shrinkWrap == true`: renders inside a parent scroll view (no own scroll)
///   and reveals the next page via a "Load More" footer button.
///
/// Paging is client-side today; [_revealNextPage] is the single hook to later
/// swap in a server-side page fetch. Pass a [resetKey] (e.g. the current search
/// query + filter) so paging restarts from page one whenever the source data
/// meaningfully changes.
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separatorBuilder,
    this.pageSize = 20,
    this.shrinkWrap = false,
    this.padding = EdgeInsets.zero,
    this.resetKey,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final int pageSize;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  /// When this value changes, paging resets to the first page.
  final Object? resetKey;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  late int _visibleCount = widget.pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetKey != oldWidget.resetKey) {
      _visibleCount = widget.pageSize;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMore => _visibleCount < widget.items.length;

  void _revealNextPage() {
    if (!_hasMore) return;
    setState(() {
      _visibleCount =
          (_visibleCount + widget.pageSize).clamp(0, widget.items.length);
    });
  }

  void _onScroll() {
    if (!_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _revealNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _visibleCount.clamp(0, widget.items.length);

    if (widget.shrinkWrap) {
      // Embedded mode — render the visible slice + a "Load more" footer.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            widget.itemBuilder(context, widget.items[i], i),
            if (widget.separatorBuilder != null && i < count - 1)
              widget.separatorBuilder!(context, i),
          ],
          if (_hasMore) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _revealNextPage,
              icon: const Icon(Icons.expand_more_rounded, size: 18),
              label: Text('Load more (${widget.items.length - count})'),
            ),
          ],
        ],
      );
    }

    // Scrollable mode — infinite scroll.
    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: count + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          widget.separatorBuilder?.call(context, index) ??
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= count) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          );
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
}
