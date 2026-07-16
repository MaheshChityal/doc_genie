import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/controller/maker_controller.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/screen/maker_doc_detail_screen.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:doc_genie/utils/snackbar_utils.dart';
import 'package:doc_genie/widgets/app_card.dart';
import 'package:doc_genie/widgets/app_loader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared tab body used for both Auto Scan and Manual Scan.
/// [isAuto] drives which providers it reads.
class ScanTabScreen extends ConsumerStatefulWidget {
  const ScanTabScreen({super.key, required this.isAuto});

  final bool isAuto;

  @override
  ConsumerState<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends ConsumerState<ScanTabScreen> {
  PlatformFile? _pickedFile;

  StateNotifierProvider<ScanController, ScanState> get _scanProvider =>
      widget.isAuto ? autoScanControllerProvider : manualScanControllerProvider;

  StateNotifierProvider<SubmitController, GenericState> get _submitProvider =>
      widget.isAuto
      ? autoSubmitControllerProvider
      : manualSubmitControllerProvider;

  StateNotifierProvider<DocsController, GenericState> get _docsProvider =>
      widget.isAuto ? autoDocsControllerProvider : manualDocsControllerProvider;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() => _pickedFile = file);
    await ref.read(_scanProvider.notifier).scan(file);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(_scanProvider);
    final submitState = ref.watch(_submitProvider);
    final docsState = ref.watch(_docsProvider);

    final isSubmitting = submitState is LoadingState;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload Zone
          _UploadZone(
            file: _pickedFile,
            isScanning: scanState.isScanning,
            onPick: _pickFile,
            onClear: () {
              setState(() => _pickedFile = null);
              ref.read(_scanProvider.notifier).reset();
              ref.read(_submitProvider.notifier).reset();
            },
          ),

          // Error
          if (scanState.error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: scanState.error!),
          ],

          // Form
          if (scanState.result != null) ...[
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: ColorConstants.surface,
              child: TransactionForm(
                type: scanState.result!.type,
                initialValues: scanState.result!.fields,
                isSubmitting: isSubmitting,
                onSubmit: (fields, isEdited) async {
                  await ref
                      .read(_submitProvider.notifier)
                      .submit(
                        documentId: scanState.result!.documentId,
                        type: scanState.result!.type,
                        fields: fields,
                        isEdited: isEdited,
                        onSuccess: (doc) {
                          ref.read(_docsProvider.notifier).prependDoc(doc);
                          ref.read(_scanProvider.notifier).reset();
                          ref.read(_submitProvider.notifier).reset();
                          setState(() => _pickedFile = null);
                          _showSuccess(context, doc.referenceNumber);
                        },
                      );
                  if (!mounted) return;
                  final errMsg = submitState is ErrorState
                      ? submitState.exception.message
                      : null;
                  if (errMsg != null) {
                    SnackBarUtils.show(errMsg, type: SnackType.error);
                  }
                },
              ),
            ),
          ],

          // Documents list
          const SizedBox(height: 28),
          Text(
            widget.isAuto ? 'Auto Scan Documents' : 'Manual Scan Documents',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 4),
          Text(
            'Your submitted documents and their current status.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          _DocsList(state: docsState, context: context),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context, String refNo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Document Submitted'),
        content: Text(
          'Reference number: $refNo\n\nYour document has been submitted for checker review.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
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
      padding: const EdgeInsets.all(24),
      backgroundColor: ColorConstants.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: ColorConstants.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: Colors.white,
                ),
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
          const SizedBox(height: 20),
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
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ColorConstants.tagBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.insert_drive_file_rounded,
                color: ColorConstants.tagFg,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                file.name,
                style: AppTextStyles.caption.copyWith(
                  color: ColorConstants.tagFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onClear,
          icon: const Icon(
            Icons.close_rounded,
            color: ColorConstants.textMuted,
            size: 20,
          ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.errorColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ColorConstants.errorColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: ColorConstants.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocsList extends StatelessWidget {
  const _DocsList({required this.state, required this.context});

  final GenericState state;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    if (state is LoadingState || state is InitialState) {
      return const AppLoader();
    }
    if (state is ErrorState) {
      return Text(
        (state as ErrorState).exception.message,
        style: AppTextStyles.caption.copyWith(color: ColorConstants.errorColor),
      );
    }
    final docs =
        (state as LoadedState<List<DocumentModel>>).response ??
        const <DocumentModel>[];
    if (docs.isEmpty) {
      return const _EmptyDocs();
    }
    return Column(
      children: [
        for (final doc in docs) ...[
          _DocumentCard(
            doc: doc,
            onView: () => navigate(context, MakerDocDetailScreen(doc: doc)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc, required this.onView});

  final DocumentModel doc;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(doc.status);
    final typeColor = _typeColor(doc.transactionType);
    return AppCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: ColorConstants.surface,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_rounded, color: typeColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.referenceNumber, style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(
                  '${doc.transactionType} · ${doc.submittedAt}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              doc.status,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: const Text('View', style: TextStyle(fontSize: 13)),
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

class _EmptyDocs extends StatelessWidget {
  const _EmptyDocs();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: ColorConstants.surface,
      child: Column(
        children: [
          const Icon(
            Icons.inbox_rounded,
            size: 38,
            color: ColorConstants.textMuted,
          ),
          const SizedBox(height: 12),
          Text('No documents yet', style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(
            'Upload and submit a document to see it here.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
