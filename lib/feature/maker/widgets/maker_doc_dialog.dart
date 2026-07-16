import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/controller/maker_controller.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the document detail as a pop-up dialog instead of a full screen.
///
/// When [isEditable] (an auto pending doc) the form is editable and shows a
/// remark entry above the Submit button; the remark is sent with the submit.
/// Otherwise the form is read-only (View).
Future<void> showMakerDocDialog(
  BuildContext context, {
  required DocumentModel doc,
  bool isEditable = false,
  VoidCallback? onSubmitSuccess,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _MakerDocDialog(
      doc: doc,
      isEditable: isEditable,
      onSubmitSuccess: onSubmitSuccess,
    ),
  );
}

class _MakerDocDialog extends ConsumerStatefulWidget {
  const _MakerDocDialog({
    required this.doc,
    required this.isEditable,
    required this.onSubmitSuccess,
  });

  final DocumentModel doc;
  final bool isEditable;
  final VoidCallback? onSubmitSuccess;

  @override
  ConsumerState<_MakerDocDialog> createState() => _MakerDocDialogState();
}

class _MakerDocDialogState extends ConsumerState<_MakerDocDialog> {
  final TextEditingController _remarkController = TextEditingController();

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit(Map<String, String> fields, String isEdited) async {
    final notifier = ref.read(autoSubmitControllerProvider.notifier);
    await notifier.submit(
      documentId: widget.doc.id,
      type: TransactionTypeX.fromString(widget.doc.transactionType),
      fields: fields,
      isEdited: isEdited,
      remark: _remarkController.text.trim(),
      onSuccess: (newDoc) {
        widget.onSubmitSuccess?.call();
        notifier.reset();
        if (!mounted) return;
        Navigator.of(context).pop();
        SnackBarUtils.show(
          'Document ${newDoc.referenceNumber} submitted for checker review.',
          type: SnackType.success,
        );
      },
    );
    if (!mounted) return;
    final state = ref.read(autoSubmitControllerProvider);
    if (state is ErrorState) {
      SnackBarUtils.show(state.exception.message, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = TransactionTypeX.fromString(widget.doc.transactionType);
    final isSubmitting = widget.isEditable &&
        ref.watch(autoSubmitControllerProvider) is LoadingState;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: ColorConstants.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(doc: widget.doc),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: TransactionForm(
                  type: type,
                  initialValues: widget.doc.fields,
                  readOnly: !widget.isEditable,
                  isSubmitting: isSubmitting,
                  belowFields: widget.isEditable ? _remarkField() : null,
                  onSubmit: (fields, isEdited) {
                    if (!widget.isEditable) return;
                    _submit(fields, isEdited);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remark',
          style: AppTextStyles.caption.copyWith(
            color: ColorConstants.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _remarkController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your remark…',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.doc});

  final DocumentModel doc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: ColorConstants.heroGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.referenceNumber,
                  style: AppTextStyles.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${doc.transactionType} · Submitted ${doc.submittedAt}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
