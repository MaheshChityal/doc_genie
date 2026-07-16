import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/checker/controller/checker_controller.dart';
import 'package:doc_genie/feature/checker/model/checker_models.dart';
import 'package:doc_genie/feature/checker/widgets/checker_doc_dialog.dart';
import 'package:doc_genie/utils/size_extension.dart';
import 'package:doc_genie/widgets/app_card.dart';
import 'package:doc_genie/widgets/app_loader.dart';
import 'package:doc_genie/widgets/error_retry.dart';
import 'package:doc_genie/widgets/paginated_list_view.dart';
import 'package:doc_genie/widgets/search_field.dart';
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
  String _searchQuery = '';

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

    final filtered = allDocs.where((d) {
      final statusOk = _filter == null || d.status == _filter;
      return statusOk && matchesCheckerQuery(d, _searchQuery);
    }).toList();

    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hero card
          AppCard(
            padding: const EdgeInsets.all(24),
            gradient: ColorConstants.heroGradient,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHECKER QUEUE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                8.height,
                const Text(
                  'Review & Authorise Documents',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.7,
                  ),
                ),
                10.height,
                Text(
                  '$pending document${pending == 1 ? '' : 's'} awaiting your review and authorisation.',
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          20.height,

          // Filter chips
          _FilterBar(
            selected: _filter,
            onSelect: (value) => setState(() => _filter = value),
            pending: pending,
            approved: approved,
            rejected: rejected,
            total: allDocs.length,
          ),
          16.height,

          // Search
          SearchField(
            hint: 'Search by reference, ID, submitter, type…',
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
          16.height,

          // Document list
          if (filtered.isEmpty)
            AppCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.inbox_rounded,
                    size: 40,
                    color: ColorConstants.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No documents match “$_searchQuery”'
                        : _filter == null
                            ? 'No documents in queue'
                            : 'No $_filter documents',
                  ),
                ],
              ),
            )
          else
            PaginatedListView<CheckerDocModel>(
              items: filtered,
              shrinkWrap: true,
              resetKey: '$_filter|$_searchQuery',
              separatorBuilder: (_, __) => 12.height,
              itemBuilder: (context, doc, index) => _CheckerDocCard(
                doc: doc,
                onView: () => showCheckerDocDialog(context, doc: doc),
              ),
            ),
        ],
      ),
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
          label: 'All',
          count: total,
          color: ColorConstants.primaryColor,
          selected: selected == null,
          onTap: () => onSelect(null),
        ),
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

class _CheckerDocCard extends StatelessWidget {
  const _CheckerDocCard({required this.doc, required this.onView});

  final CheckerDocModel doc;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(doc.status);
    final typeColor = _typeColor(doc.transactionType);

    return AppCard(
      padding: const EdgeInsets.all(13),
      backgroundColor: ColorConstants.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                doc.id,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  doc.transactionType,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          5.height,
          Text(doc.referenceNumber, style: AppTextStyles.subtitle),
          3.height,
          Text(
            'Submitted by ${doc.submittedBy} · ${doc.date}',
            style: AppTextStyles.caption,
          ),
          10.height,
          Row(
            children: [
              _StatusBadge(status: doc.status, color: statusColor),
              const Spacer(),
              FilledButton.icon(
                onPressed: onView,
                style: FilledButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('View', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return ColorConstants.successColor;
      case 'Rejected':
        return ColorConstants.errorColor;
      default:
        return ColorConstants.warningColor;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'RTGS':
        return ColorConstants.infoColor;
      case 'NEFT':
        return ColorConstants.secondaryColor;
      default:
        return ColorConstants.accentColor;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          6.width,
          Text(
            status,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
