import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/checker/controller/checker_controller.dart';
import 'package:doc_genie/feature/checker/model/checker_models.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a checker document as a pop-up dialog (mirrors the maker dialog).
///
/// The document fields scroll within the dialog while the Approve / Reject
/// actions stay pinned at the bottom. Tapping an action opens the remark
/// dialog and then submits the decision.
Future<void> showCheckerDocDialog(
  BuildContext context, {
  required CheckerDocModel doc,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CheckerDocDialog(doc: doc),
  );
}

class _CheckerDocDialog extends ConsumerStatefulWidget {
  const _CheckerDocDialog({required this.doc});

  final CheckerDocModel doc;

  @override
  ConsumerState<_CheckerDocDialog> createState() => _CheckerDocDialogState();
}

class _CheckerDocDialogState extends ConsumerState<_CheckerDocDialog> {
  CheckerDocModel get _doc => widget.doc;

  Future<void> _confirmDecision(String decision) async {
    final remarkController = TextEditingController();
    final isApprove = decision == 'Approved';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Approve Document' : 'Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a remark before ${isApprove ? 'approving' : 'rejecting'} this document.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarkController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter your remark…',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isApprove
                  ? ColorConstants.successColor
                  : ColorConstants.errorColor,
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    remarkController.dispose();
    if (confirmed == true && mounted) {
      await _decide(decision);
    }
  }

  Future<void> _decide(String decision) async {
    final error = await ref
        .read(checkerControllerProvider.notifier)
        .decide(_doc.id, decision);
    if (!mounted) return;
    if (error != null) {
      SnackBarUtils.show(error, type: SnackType.error);
      return;
    }
    // Close the detail dialog, then show feedback via the global navigator.
    Navigator.of(context).pop();
    SnackBarUtils.show(
      '${_doc.referenceNumber} ${decision == 'Approved' ? 'approved' : 'rejected'} successfully',
      type: decision == 'Approved' ? SnackType.success : SnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final decided = _doc.status != 'Pending';
    final type = TransactionTypeX.fromString(_doc.transactionType);
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: ColorConstants.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 780, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(doc: _doc),
            const Divider(height: 1),
            // Scrollable content.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // _StatusBanner(status: _doc.status),
                    // const SizedBox(height: 20),
                    Text(
                      'Document Details',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 6),
                    // Text(
                    //   'Submitted on ${_doc.date} by ${_doc.submittedBy}',
                    //   style: AppTextStyles.caption,
                    // ),
                    // const SizedBox(height: 16),
                    TransactionForm(
                      type: type,
                      initialValues: _doc.fields,
                      readOnly: true,
                      onSubmit: (fields, isEdited) {},
                    ),
                  ],
                ),
              ),
            ),
            // Pinned action bar — stays put while the content above scrolls.
            if (!decided) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDecision('Rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.errorColor,
                          side: const BorderSide(
                            color: ColorConstants.errorColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _confirmDecision('Approved'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorConstants.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.doc});

  final CheckerDocModel doc;

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
                  '${doc.transactionType} · Submitted by ${doc.submittedBy}',
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

// class _StatusBanner extends StatelessWidget {
//   const _StatusBanner({required this.status});

//   final String status;

//   static Color _color(String s) {
//     switch (s) {
//       case 'Approved':
//         return ColorConstants.successColor;
//       case 'Rejected':
//         return ColorConstants.errorColor;
//       default:
//         return ColorConstants.warningColor;
//     }
//   }

//   static IconData _icon(String s) {
//     switch (s) {
//       case 'Approved':
//         return Icons.check_circle_rounded;
//       case 'Rejected':
//         return Icons.cancel_rounded;
//       default:
//         return Icons.schedule_rounded;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final color = _color(status);
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withValues(alpha: 0.22)),
//       ),
//       child: Row(
//         children: [
//           Icon(_icon(status), color: color, size: 24),
//           const SizedBox(width: 12),
//           Text(
//             status == 'Pending' ? 'Awaiting Review' : status,
//             style: AppTextStyles.subtitle.copyWith(color: color),
//           ),
//         ],
//       ),
//     );
//   }
// }
