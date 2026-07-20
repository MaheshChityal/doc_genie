import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/checker/controller/checker_controller.dart';
import 'package:doc_genie/feature/checker/model/checker_models.dart';
import 'package:doc_genie/feature/checker/widgets/checker_doc_dialog.dart';
import 'package:doc_genie/widgets/app_loader.dart';
import 'package:doc_genie/widgets/error_retry.dart';
import 'package:doc_genie/widgets/paginated_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client-side search predicate for a [CheckerDocModel].
bool matchesCheckerQuery(CheckerDocModel d, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  return d.id.toLowerCase().contains(q) ||
      d.referenceNumber.toLowerCase().contains(q) ||
      d.submittedBy.toLowerCase().contains(q) ||
      d.transactionType.toLowerCase().contains(q) ||
      d.status.toLowerCase().contains(q);
}

class CheckerScreen extends ConsumerStatefulWidget {
  const CheckerScreen({super.key});

  @override
  ConsumerState<CheckerScreen> createState() => _CheckerScreenState();
}

class _CheckerScreenState extends ConsumerState<CheckerScreen> {
  // null = All
  String? _filter = 'Pending';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkerControllerProvider);

    if (state is LoadingState || state is InitialState) {
      return const AppLoader();
    }

    if (state is ErrorState) {
      return ErrorRetry(
        message: state.exception.message,
        onRetry: () => ref
            .read(checkerControllerProvider.notifier)
            .fetchDocuments(shouldRefresh: true),
      );
    }

    final allDocs = (state as LoadedState<List<CheckerDocModel>>).response ??
        const <CheckerDocModel>[];
    final pending = allDocs.where((d) => d.status == 'Pending').length;
    final approved = allDocs.where((d) => d.status == 'Approved').length;
    final rejected = allDocs.where((d) => d.status == 'Rejected').length;

    final filtered = _filter == null
        ? allDocs
        : allDocs.where((d) => d.status == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppCard(
              //   padding: const EdgeInsets.all(18),
              //   gradient: ColorConstants.heroGradient,
              //   borderColor: Colors.transparent,
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Text(
              //         'CHECKER QUEUE',
              //         style: TextStyle(
              //           color: Colors.white70,
              //           fontSize: 11,
              //           fontWeight: FontWeight.w800,
              //           letterSpacing: 1.1,
              //         ),
              //       ),
              //       6.height,
              //       const Text(
              //         'Review & Authorise Documents',
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 22,
              //           fontWeight: FontWeight.w800,
              //           height: 1.05,
              //           letterSpacing: -0.6,
              //         ),
              //       ),
              //       6.height,
              //       Text(
              //         '$pending document${pending == 1 ? '' : 's'} awaiting your review and authorisation.',
              //         style: const TextStyle(
              //           color: Color(0xD9FFFFFF),
              //           fontSize: 13,
              //           height: 1.4,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
        Expanded(
          child: PaginatedTable<CheckerDocModel>(
            key: ValueKey(_filter),
            items: filtered,
            searchHint: 'Search by id, file, maker, type…',
            searchPredicate: matchesCheckerQuery,
            filters: _FilterBar(
              selected: _filter,
              onSelect: (value) => setState(() => _filter = value),
              pending: pending,
              approved: approved,
              rejected: rejected,
              total: allDocs.length,
            ),
            columns: [
              TableColumn(
                label: 'Id',
                flex: 2,
                cell: (_, d) => Text(
                  d.id,
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TableColumn(
                label: 'FileName',
                flex: 4,
                cell: (_, d) => Text(
                  d.fileName.isEmpty ? '—' : d.fileName,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TableColumn(
                label: 'Maker By',
                flex: 3,
                cell: (_, d) => Text(
                  d.submittedBy.isEmpty ? '—' : d.submittedBy,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TableColumn(
                label: 'Action',
                flex: 3,
                cell: (context, d) => Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => showCheckerDocDialog(context, doc: d),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelect,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.total,
  });

  final String? selected;
  final ValueChanged<String?> onSelect;
  final int pending;
  final int approved;
  final int rejected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Pending',
          count: pending,
          color: ColorConstants.warningColor,
          selected: selected == 'Pending',
          onTap: () => onSelect('Pending'),
        ),
        _FilterChip(
          label: 'Approved',
          count: approved,
          color: ColorConstants.successColor,
          selected: selected == 'Approved',
          onTap: () => onSelect('Approved'),
        ),
        _FilterChip(
          label: 'Rejected',
          count: rejected,
          color: ColorConstants.errorColor,
          selected: selected == 'Rejected',
          onTap: () => onSelect('Rejected'),
        ),
        _FilterChip(
          label: 'All',
          count: total,
          color: ColorConstants.primaryColor,
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
