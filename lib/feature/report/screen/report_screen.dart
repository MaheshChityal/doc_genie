import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/report/controller/report_controller.dart';
import 'package:doc_genie/feature/report/model/report_model.dart';
import 'package:doc_genie/widgets/app_loader.dart';
import 'package:doc_genie/widgets/error_retry.dart';
import 'package:doc_genie/widgets/paginated_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _matchesReportQuery(ReportDoc d, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  return d.referenceNumber.toLowerCase().contains(q) ||
      d.transactionType.toLowerCase().contains(q) ||
      d.status.toLowerCase().contains(q) ||
      d.submittedBy.toLowerCase().contains(q) ||
      d.fileName.toLowerCase().contains(q);
}

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _statusFilter;
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);

    if (state is LoadingState || state is InitialState) {
      return const AppLoader();
    }

    if (state is ErrorState) {
      return ErrorRetry(
        message: state.exception.message,
        onRetry: () => ref
            .read(reportControllerProvider.notifier)
            .fetchReport(shouldRefresh: true),
      );
    }

    final report = (state as LoadedState<ReportModel>).response ??
        const ReportModel(
            stats: ReportStats(
                total: 0,
                pending: 0,
                approved: 0,
                rejected: 0,
                rtgs: 0,
                neft: 0,
                fundTransfer: 0),
            documents: []);

    final docs = report.documents.where((d) {
      final statusOk = _statusFilter == null || d.status == _statusFilter;
      final typeOk = _typeFilter == null || d.transactionType == _typeFilter;
      return statusOk && typeOk;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards + type breakdown
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _SummaryRow(stats: report.stats),
              // const SizedBox(height: 12),
              _TypeBreakdownRow(stats: report.stats),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Document table
        Expanded(
          child: PaginatedTable<ReportDoc>(
            key: ValueKey('$_statusFilter/$_typeFilter'),
            items: docs,
            searchHint: 'Search by reference, type, maker…',
            searchPredicate: _matchesReportQuery,
            filters: _FilterBar(
              statusFilter: _statusFilter,
              typeFilter: _typeFilter,
              onStatusSelect: (v) => setState(() => _statusFilter = v),
              onTypeSelect: (v) => setState(() => _typeFilter = v),
              stats: report.stats,
            ),
            columns: [
              TableColumn(
                label: 'Reference No.',
                flex: 4,
                cell: (_, d) => Text(
                  d.referenceNumber,
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TableColumn(
                label: 'Type',
                flex: 3,
                cell: (_, d) => _TypeBadge(type: d.transactionType),
              ),
              TableColumn(
                label: 'Status',
                flex: 3,
                cell: (_, d) => _StatusBadge(status: d.status),
              ),
              TableColumn(
                label: 'Submitted By',
                flex: 3,
                cell: (_, d) => Text(
                  d.submittedBy.isEmpty ? '—' : d.submittedBy,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TableColumn(
                label: 'Date',
                flex: 3,
                cell: (_, d) => Text(
                  d.date.isEmpty ? '—' : d.date,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TableColumn(
                label: 'File',
                flex: 4,
                cell: (_, d) => Text(
                  d.fileName.isEmpty ? '—' : d.fileName,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Summary cards ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});

  final ReportStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 700 ? 4 : 2;
        final items = [
          (
            label: 'Total Documents',
            value: stats.total,
            color: ColorConstants.primaryColor,
            icon: Icons.description_rounded
          ),
          (
            label: 'Pending Review',
            value: stats.pending,
            color: ColorConstants.warningColor,
            icon: Icons.schedule_rounded
          ),
          (
            label: 'Approved',
            value: stats.approved,
            color: ColorConstants.successColor,
            icon: Icons.check_circle_rounded
          ),
          (
            label: 'Rejected',
            value: stats.rejected,
            color: ColorConstants.errorColor,
            icon: Icons.cancel_rounded
          ),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 88,
          ),
          itemBuilder: (_, i) => _StatCard(
            label: items[i].label,
            value: items[i].value,
            color: items[i].color,
            icon: items[i].icon,
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: AppTextStyles.title.copyWith(
                    color: color,
                    fontSize: 22,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type breakdown ───────────────────────────────────────────────────────────

class _TypeBreakdownRow extends StatelessWidget {
  const _TypeBreakdownRow({required this.stats});

  final ReportStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 600 ? 3 : 1;
        final items = [
          (
            label: 'RTGS',
            value: stats.rtgs,
            color: ColorConstants.infoColor,
            icon: Icons.swap_horiz_rounded
          ),
          (
            label: 'NEFT',
            value: stats.neft,
            color: ColorConstants.secondaryColor,
            icon: Icons.account_balance_rounded
          ),
          (
            label: 'Fund Transfer',
            value: stats.fundTransfer,
            color: ColorConstants.accentColor,
            icon: Icons.send_rounded
          ),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 76,
          ),
          itemBuilder: (_, i) => _TypeCard(
            label: items[i].label,
            value: items[i].value,
            color: items[i].color,
            icon: items[i].icon,
            total: stats.total,
          ),
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.total,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      '$value',
                      style: AppTextStyles.subtitle.copyWith(color: color),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    Text(
                      '${(pct * 100).round()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: color.withValues(alpha: 0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.statusFilter,
    required this.typeFilter,
    required this.onStatusSelect,
    required this.onTypeSelect,
    required this.stats,
  });

  final String? statusFilter;
  final String? typeFilter;
  final ValueChanged<String?> onStatusSelect;
  final ValueChanged<String?> onTypeSelect;
  final ReportStats stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Status chips
        _Chip(
            label: 'All',
            count: stats.total,
            color: ColorConstants.primaryColor,
            selected: statusFilter == null && typeFilter == null,
            onTap: () {
              onStatusSelect(null);
              onTypeSelect(null);
            }),
        _Chip(
            label: 'Pending',
            count: stats.pending,
            color: ColorConstants.warningColor,
            selected: statusFilter == 'Pending',
            onTap: () =>
                onStatusSelect(statusFilter == 'Pending' ? null : 'Pending')),
        _Chip(
            label: 'Approved',
            count: stats.approved,
            color: ColorConstants.successColor,
            selected: statusFilter == 'Approved',
            onTap: () =>
                onStatusSelect(statusFilter == 'Approved' ? null : 'Approved')),
        _Chip(
            label: 'Rejected',
            count: stats.rejected,
            color: ColorConstants.errorColor,
            selected: statusFilter == 'Rejected',
            onTap: () =>
                onStatusSelect(statusFilter == 'Rejected' ? null : 'Rejected')),
        // Divider
        const SizedBox(width: 4),
        _Chip(
            label: 'RTGS',
            count: stats.rtgs,
            color: ColorConstants.infoColor,
            selected: typeFilter == 'RTGS',
            onTap: () => onTypeSelect(typeFilter == 'RTGS' ? null : 'RTGS')),
        _Chip(
            label: 'NEFT',
            count: stats.neft,
            color: ColorConstants.secondaryColor,
            selected: typeFilter == 'NEFT',
            onTap: () => onTypeSelect(typeFilter == 'NEFT' ? null : 'NEFT')),
        _Chip(
            label: 'Fund Transfer',
            count: stats.fundTransfer,
            color: ColorConstants.accentColor,
            selected: typeFilter == 'Fund Transfer',
            onTap: () => onTypeSelect(
                typeFilter == 'Fund Transfer' ? null : 'Fund Transfer')),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Row badges ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  static Color _color(String s) {
    switch (s) {
      case 'Approved':
        return ColorConstants.successColor;
      case 'Rejected':
        return ColorConstants.errorColor;
      default:
        return ColorConstants.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: AppTextStyles.caption
            .copyWith(color: c, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  static Color _color(String t) {
    switch (t) {
      case 'RTGS':
        return ColorConstants.infoColor;
      case 'NEFT':
        return ColorConstants.secondaryColor;
      default:
        return ColorConstants.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        type.isEmpty ? '—' : type,
        style: AppTextStyles.caption
            .copyWith(color: c, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
