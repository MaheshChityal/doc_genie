import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/size_extension.dart';
import 'package:doc_genie/widgets/screen_header_bar.dart';
import 'package:flutter/material.dart';

class MakerDocDetailScreen extends StatelessWidget {
  const MakerDocDetailScreen({super.key, required this.doc});

  final DocumentModel doc;

  @override
  Widget build(BuildContext context) {
    final type = TransactionTypeX.fromString(doc.transactionType);
    final statusColor = _statusColor(doc.status);

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: doc.referenceNumber,
        subtitle: '${doc.transactionType} · Submitted ${doc.submittedAt}',
        icon: Icons.description_rounded,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Status banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.22)),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(doc.status), color: statusColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      doc.status == 'Pending' ? 'Awaiting Checker Review' : doc.status,
                      style: AppTextStyles.subtitle.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              24.height,
              Text(
                'Document Details',
                style: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
              6.height,
              Text(
                'Reference: ${doc.referenceNumber}  ·  Submitted: ${doc.submittedAt}',
                style: AppTextStyles.caption,
              ),
              20.height,
              TransactionForm(
                type: type,
                initialValues: doc.fields,
                readOnly: true,
                onSubmit: (fields, isEdited) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'Approved':
        return ColorConstants.successColor;
      case 'Rejected':
        return ColorConstants.errorColor;
      default:
        return ColorConstants.warningColor;
    }
  }

  static IconData _statusIcon(String s) {
    switch (s) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}
