import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/widgets/search_field.dart';
import 'package:flutter/material.dart';

/// One column of a [PaginatedTable].
class TableColumn<T> {
  const TableColumn({required this.label, required this.cell, this.flex = 1});

  final String label;
  final int flex;
  final Widget Function(BuildContext context, T item) cell;
}

/// A client-side paginated table: a search box on top, rows in the middle, and
/// a footer with a page-size selector (25/50/100) plus first/prev/next/last.
///
/// Slicing is done in-memory; this is the single place to later swap in a
/// server-side page fetch.
class PaginatedTable<T> extends StatefulWidget {
  const PaginatedTable({
    super.key,
    required this.items,
    required this.columns,
    required this.searchPredicate,
    this.searchHint = 'Search…',
    this.minTableWidth = 620,
    this.filters,
  });

  final List<T> items;
  final List<TableColumn<T>> columns;
  final bool Function(T item, String query) searchPredicate;
  final String searchHint;
  final double minTableWidth;

  /// Optional widget (e.g. status filter chips) shown on the same row as the
  /// search box, to its left.
  final Widget? filters;

  @override
  State<PaginatedTable<T>> createState() => _PaginatedTableState<T>();
}

class _PaginatedTableState<T> extends State<PaginatedTable<T>> {
  static const _pageSizes = [10, 25, 50, 100];
  String _query = '';
  int _pageSize = 25;
  int _page = 0; // 0-based

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.items.where((e) => widget.searchPredicate(e, _query)).toList();
    final total = filtered.length;
    final pageCount = total == 0 ? 1 : ((total - 1) ~/ _pageSize) + 1;
    final page = _page.clamp(0, pageCount - 1);
    final start = page * _pageSize;
    final end = (start + _pageSize) > total ? total : (start + _pageSize);
    final rows = total == 0 ? <T>[] : filtered.sublist(start, end);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              if (widget.filters != null) ...[
                widget.filters!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SearchField(
                  hint: widget.searchHint,
                  onChanged: (q) => setState(() {
                    _query = q;
                    _page = 0;
                  }),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: total == 0
              ? _EmptyState(query: _query)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final tight = constraints.maxWidth < widget.minTableWidth;
                    final table = SizedBox(
                      width:
                          tight ? widget.minTableWidth : constraints.maxWidth,
                      child: Column(
                        children: [
                          _headerRow(),
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: rows.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: ColorConstants.border,
                              ),
                              itemBuilder: (context, i) => _dataRow(rows[i], i),
                            ),
                          ),
                        ],
                      ),
                    );
                    return tight
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: table,
                          )
                        : table;
                  },
                ),
        ),
        _Footer(
          total: total,
          start: total == 0 ? 0 : start + 1,
          end: end,
          page: page,
          pageCount: pageCount,
          pageSize: _pageSize,
          pageSizes: _pageSizes,
          onPageSize: (v) => setState(() {
            _pageSize = v;
            _page = 0;
          }),
          onFirst: () => setState(() => _page = 0),
          onPrev: () => setState(() => _page = page - 1),
          onNext: () => setState(() => _page = page + 1),
          onLast: () => setState(() => _page = pageCount - 1),
        ),
      ],
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: ColorConstants.surfaceAlt,
        border: Border(bottom: BorderSide(color: ColorConstants.border)),
      ),
      child: Row(
        children: [
          for (final c in widget.columns)
            Expanded(
              flex: c.flex,
              child: Text(
                c.label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dataRow(T item, int index) {
    return Container(
      color: index.isOdd
          ? ColorConstants.surfaceAlt.withValues(alpha: 0.35)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final c in widget.columns)
            Expanded(
              flex: c.flex,
              child: Align(
                alignment: Alignment.centerLeft,
                child: c.cell(context, item),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded,
              size: 40, color: ColorConstants.textMuted),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty ? 'No results for “$query”' : 'No records',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.total,
    required this.start,
    required this.end,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.pageSizes,
    required this.onPageSize,
    required this.onFirst,
    required this.onPrev,
    required this.onNext,
    required this.onLast,
  });

  final int total;
  final int start;
  final int end;
  final int page;
  final int pageCount;
  final int pageSize;
  final List<int> pageSizes;
  final ValueChanged<int> onPageSize;
  final VoidCallback onFirst;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onLast;

  @override
  Widget build(BuildContext context) {
    final atStart = page <= 0;
    final atEnd = page >= pageCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ColorConstants.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        spacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rows per page', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: pageSize,
                isDense: true,
                underline: const SizedBox.shrink(),
                style: AppTextStyles.caption.copyWith(
                  color: ColorConstants.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final s in pageSizes)
                    DropdownMenuItem(value: s, child: Text('$s')),
                ],
                onChanged: (v) {
                  if (v != null) onPageSize(v);
                },
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$start–$end of $total', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              _NavBtn(
                  icon: Icons.first_page_rounded,
                  onTap: atStart ? null : onFirst),
              _NavBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: atStart ? null : onPrev),
              _NavBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: atEnd ? null : onNext),
              _NavBtn(
                  icon: Icons.last_page_rounded, onTap: atEnd ? null : onLast),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      padding: EdgeInsets.zero,
      color: ColorConstants.textPrimary,
      disabledColor: ColorConstants.textMuted.withValues(alpha: 0.4),
    );
  }
}
