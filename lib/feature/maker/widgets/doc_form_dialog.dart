import 'dart:typed_data';

import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:doc_genie/widgets/app_button.dart';
import 'package:doc_genie/widgets/document_preview_pane.dart';
import 'package:doc_genie/widgets/success_dialog.dart';
import 'package:flutter/material.dart';

/// Reusable two-pane document dialog: PDF preview on the left, transaction
/// form on the right. Shared by Auto Scan (edit/view) and Manual Upload.
///
/// [onSubmit] performs the actual submit and returns the created reference
/// number on success, or `null` if it failed (the caller surfaces the error).
/// On success the dialog closes and a success dialog is shown. When [onSubmit]
/// is `null` the form is read-only (View — no Submit button).
Future<void> showDocFormDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String fileName,
  Uint8List? fileBytes,
  required TransactionType type,
  required Map<String, String> initialValues,
  Future<String?> Function(Map<String, String> fields, String isEdited)?
      onSubmit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _DocFormDialog(
      title: title,
      subtitle: subtitle,
      fileName: fileName,
      fileBytes: fileBytes,
      type: type,
      initialValues: initialValues,
      onSubmit: onSubmit,
    ),
  );
}

class _DocFormDialog extends StatefulWidget {
  const _DocFormDialog({
    required this.title,
    required this.subtitle,
    required this.fileName,
    required this.fileBytes,
    required this.type,
    required this.initialValues,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final String fileName;
  final Uint8List? fileBytes;
  final TransactionType type;
  final Map<String, String> initialValues;
  final Future<String?> Function(Map<String, String> fields, String isEdited)?
      onSubmit;

  @override
  State<_DocFormDialog> createState() => _DocFormDialogState();
}

class _DocFormDialogState extends State<_DocFormDialog> {
  final GlobalKey<TransactionFormState> _formKey = GlobalKey();
  bool _submitting = false;

  bool get _editable => widget.onSubmit != null;

  Future<void> _handleSubmit(
      Map<String, String> fields, String isEdited) async {
    final onSubmit = widget.onSubmit;
    if (onSubmit == null || _submitting) return;
    setState(() => _submitting = true);
    final refNo = await onSubmit(fields, isEdited);
    if (!mounted) return;
    if (refNo != null) {
      Navigator.of(context).pop();
      showSuccessDialog(
        navigatorKey.currentContext ?? context,
        title: 'Document Submitted',
        message: 'Your document has been submitted for checker review.',
        referenceNumber: refNo,
      );
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: ColorConstants.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1180, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: widget.title, subtitle: widget.subtitle),
            const Divider(height: 1),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final form = _formPane();
                  // Two panes on wide dialogs; form-only when narrow.
                  if (constraints.maxWidth < 860) return form;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: DocumentPreviewPane(
                          fileName: widget.fileName,
                          fileBytes: widget.fileBytes,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 6, child: form),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formPane() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: TransactionForm(
              key: _formKey,
              type: widget.type,
              initialValues: widget.initialValues,
              readOnly: !_editable,
              showActions: false,
              onSubmit: (fields, isEdited) {
                if (!_editable) return;
                _handleSubmit(fields, isEdited);
              },
            ),
          ),
        ),
        // Pinned Submit — stays put while the fields scroll.
        if (_editable) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Submit',
              onPressed: () => _formKey.currentState?.submit(),
              isLoading: _submitting,
            ),
          ),
        ],
      ],
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
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
                  title,
                  style: AppTextStyles.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
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
