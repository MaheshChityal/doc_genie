import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/controller/auto_controller.dart';
import 'package:doc_genie/feature/maker/controller/manual_controller.dart';
import 'package:doc_genie/feature/maker/model/auto_doc_model.dart';
import 'package:doc_genie/feature/maker/widgets/maker_doc_dialog.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/snackbar_utils.dart';
import 'package:doc_genie/widgets/app_card.dart';
import 'package:doc_genie/widgets/app_loader.dart';
import 'package:doc_genie/widgets/paginated_table.dart';
import 'package:doc_genie/widgets/success_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab body for Auto Scan (a paginated table) and Manual Upload (upload → form).
class ScanTabScreen extends ConsumerStatefulWidget {
  const ScanTabScreen({super.key, required this.isAuto});

  final bool isAuto;

  @override
  ConsumerState<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends ConsumerState<ScanTabScreen> {
  PlatformFile? _pickedFile;
  String? _autoFilter = 'Pending'; // null = All

  @override
  Widget build(BuildContext context) {
    return widget.isAuto ? _buildAuto() : _buildManual();
  }

  // ── Auto Scan ───────────────────────────────────────────────────────────
  Widget _buildAuto() {
    final state = ref.watch(autoDocsControllerProvider);

    if (state is LoadingState || state is InitialState) {
      return const AppLoader();
    }
    if (state is ErrorState) {
      return _AutoError(
        message: state.exception.message,
        onRetry: () => ref
            .read(autoDocsControllerProvider.notifier)
            .fetchDocs(shouldRefresh: true),
      );
    }

    final allDocs =
        (state as LoadedState<List<AutoDocModel>>).response ??
            const <AutoDocModel>[];
    final pending = allDocs.where((d) => d.status == 'Pending').length;
    final approved = allDocs.where((d) => d.status == 'Approved').length;
    final rejected = allDocs.where((d) => d.status == 'Rejected').length;

    final filtered = _autoFilter == null
        ? allDocs
        : allDocs.where((d) => d.status == _autoFilter).toList();

    return PaginatedTable<AutoDocModel>(
      key: ValueKey(_autoFilter),
      items: filtered,
      searchHint: 'Search by id, file, maker, type…',
      searchPredicate: _matchesAutoDoc,
      filters: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusFilterChip(
            label: 'All',
            count: allDocs.length,
            color: ColorConstants.primaryColor,
            selected: _autoFilter == null,
            onTap: () => setState(() => _autoFilter = null),
          ),
          const SizedBox(width: 8),
          _StatusFilterChip(
            label: 'Pending',
            count: pending,
            color: ColorConstants.warningColor,
            selected: _autoFilter == 'Pending',
            onTap: () => setState(() => _autoFilter = 'Pending'),
          ),
          const SizedBox(width: 8),
          _StatusFilterChip(
            label: 'Approved',
            count: approved,
            color: ColorConstants.successColor,
            selected: _autoFilter == 'Approved',
            onTap: () => setState(() => _autoFilter = 'Approved'),
          ),
          const SizedBox(width: 8),
          _StatusFilterChip(
            label: 'Rejected',
            count: rejected,
            color: ColorConstants.errorColor,
            selected: _autoFilter == 'Rejected',
            onTap: () => setState(() => _autoFilter = 'Rejected'),
          ),
        ],
      ),
      columns: [
        TableColumn(
          label: 'Id',
          flex: 2,
          cell: (_, d) => Text(d.id, style: _cellStrong),
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
            d.makerBy.isEmpty ? '—' : d.makerBy,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TableColumn(
          label: 'Action',
          flex: 3,
          cell: (context, d) {
            final isPending = d.status == 'Pending';
            return Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => showMakerDocDialog(
                  context,
                  doc: d,
                  isEditable: isPending,
                  onSubmitSuccess: isPending
                      ? () => ref
                          .read(autoDocsControllerProvider.notifier)
                          .removeDoc(d.id)
                      : null,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  isPending
                      ? Icons.edit_rounded
                      : Icons.open_in_new_rounded,
                  size: 14,
                ),
                label: Text(
                  isPending ? 'Edit & Submit' : 'View',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static bool _matchesAutoDoc(AutoDocModel d, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return d.id.toLowerCase().contains(q) ||
        d.fileName.toLowerCase().contains(q) ||
        d.makerBy.toLowerCase().contains(q) ||
        d.referenceNumber.toLowerCase().contains(q) ||
        d.transactionType.toLowerCase().contains(q) ||
        d.status.toLowerCase().contains(q) ||
        (d.fields['beneficiaryName'] ?? '').toLowerCase().contains(q);
  }

  // ── Manual Upload ───────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() => _pickedFile = file);
    await ref.read(manualScanControllerProvider.notifier).scan(file);
  }

  Widget _buildManual() {
    final scanState = ref.watch(manualScanControllerProvider);
    final submitState = ref.watch(manualSubmitControllerProvider);
    final isSubmitting = submitState is LoadingState;
    final result = scanState.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UploadZone(
            file: _pickedFile,
            isScanning: scanState.isScanning,
            onPick: _pickFile,
            onClear: () {
              setState(() => _pickedFile = null);
              ref.read(manualScanControllerProvider.notifier).reset();
              ref.read(manualSubmitControllerProvider.notifier).reset();
            },
          ),
          if (scanState.error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: scanState.error!),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(18),
              backgroundColor: ColorConstants.surface,
              child: TransactionForm(
                type: result.type,
                initialValues: result.fields,
                isSubmitting: isSubmitting,
                maxColumns: 3,
                onSubmit: (fields, isEdited) async {
                  await ref
                      .read(manualSubmitControllerProvider.notifier)
                      .submit(
                        type: result.type,
                        fields: fields,
                        isEdited: isEdited,
                        fileName: result.fileName,
                        onSuccess: (refNo) {
                          ref
                              .read(manualScanControllerProvider.notifier)
                              .reset();
                          ref
                              .read(manualSubmitControllerProvider.notifier)
                              .reset();
                          setState(() => _pickedFile = null);
                          showSuccessDialog(
                            context,
                            title: 'Document Submitted',
                            message:
                                'Your document has been submitted for checker review.',
                            referenceNumber: refNo,
                          );
                        },
                      );
                  if (!mounted) return;
                  final latest = ref.read(manualSubmitControllerProvider);
                  if (latest is ErrorState) {
                    SnackBarUtils.show(latest.exception.message,
                        type: SnackType.error);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _cellStrong = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w700,
  color: ColorConstants.textPrimary,
);

// ── Shared presentational widgets ──────────────────────────────────────────
class _AutoError extends StatelessWidget {
  const _AutoError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: ColorConstants.errorColor),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.caption
                  .copyWith(color: ColorConstants.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({
    required this.file,
    required this.isScanning,
    required this.onPick,
    required this.onClear,
  });

  final PlatformFile? file;
  final bool isScanning;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: ColorConstants.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: ColorConstants.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.upload_file_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Document', style: AppTextStyles.subtitle),
                    Text('PDF, JPG or PNG', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isScanning)
            const _ScanningIndicator()
          else if (file != null)
            _FileChip(file: file!, onClear: onClear)
          else
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Choose File'),
            ),
        ],
      ),
    );
  }
}

class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(width: 12),
        Text(
          'Scanning document…',
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.file, required this.onClear});

  final PlatformFile file;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ColorConstants.tagBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file_rounded,
                    color: ColorConstants.tagFg, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: ColorConstants.tagFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded,
              color: ColorConstants.textMuted, size: 20),
          tooltip: 'Remove file',
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorConstants.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: ColorConstants.errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: ColorConstants.errorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption
                  .copyWith(color: ColorConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
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
