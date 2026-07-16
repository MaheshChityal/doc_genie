import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/checker/controller/checker_controller.dart';
import 'package:doc_genie/feature/checker/model/checker_models.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/size_extension.dart';
import 'package:doc_genie/utils/snackbar_utils.dart';
import 'package:doc_genie/widgets/screen_header_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckerDetailScreen extends ConsumerStatefulWidget {
  const CheckerDetailScreen({super.key, required this.doc});

  final CheckerDocModel doc;

  @override
  ConsumerState<CheckerDetailScreen> createState() =>
      _CheckerDetailScreenState();
}

class _CheckerDetailScreenState extends ConsumerState<CheckerDetailScreen> {
  late CheckerDocModel _doc;

  @override
  void initState() {
    super.initState();
    _doc = widget.doc;
  }

  Future<void> _decide(String decision) async {
    final error = await ref
        .read(checkerControllerProvider.notifier)
        .decide(_doc.id, decision);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: ColorConstants.errorColor,
        ),
      );
      return;
    }
    // Show snackbar via navigatorKey so it appears on the list screen after pop
    SnackBarUtils.show(
      '${_doc.referenceNumber} ${decision == 'Approved' ? 'approved' : 'rejected'} successfully',
      type: decision == 'Approved' ? SnackType.success : SnackType.error,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final decided = _doc.status != 'Pending';
    final type = TransactionTypeX.fromString(_doc.transactionType);

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: _doc.referenceNumber,
        subtitle: '${_doc.transactionType} · Submitted by ${_doc.submittedBy}',
        icon: Icons.description_rounded,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatusBanner(status: _doc.status),
              24.height,
              Text('Document Details', style: AppTextStyles.heading.copyWith(fontSize: 22)),
              6.height,
              Text(
                'Submitted on ${_doc.date} by ${_doc.submittedBy}',
                style: AppTextStyles.caption,
              ),
              20.height,
              TransactionForm(
                type: type,
                initialValues: _doc.fields,
                readOnly: true,
                onSubmit: (fields, isEdited) {},
              ),
              if (!decided) ...[
                24.height,
                const Divider(),
                20.height,
                Text(
                  'Take Action',
                  style: AppTextStyles.title,
                ),
                8.height,
                Text(
                  'Review the fields above and approve or reject this document.',
                  style: AppTextStyles.caption,
                ),
                16.height,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _decide('Rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.errorColor,
                          side: const BorderSide(
                            color: ColorConstants.errorColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text('Reject'),
                      ),
                    ),
                    16.width,
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _decide('Approved'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorConstants.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

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

  static IconData _icon(String s) {
    switch (s) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(_icon(status), color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            status == 'Pending' ? 'Awaiting Review' : status,
            style: AppTextStyles.subtitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
