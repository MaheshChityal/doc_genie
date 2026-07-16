import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/controller/maker_controller.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/widgets/transaction_form.dart';
import 'package:doc_genie/utils/size_extension.dart';
import 'package:doc_genie/widgets/screen_header_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MakerDocDetailScreen extends ConsumerWidget {
  const MakerDocDetailScreen({
    super.key,
    required this.doc,
    this.isEditable = false,
    this.onSubmitSuccess,
  });

  final DocumentModel doc;
  final bool isEditable;
  final VoidCallback? onSubmitSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting =
        isEditable && ref.watch(autoSubmitControllerProvider) is LoadingState;
    final type = TransactionTypeX.fromString(doc.transactionType);

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
                readOnly: !isEditable,
                isSubmitting: isSubmitting,
                onSubmit: (fields, isEdited) {
                  if (!isEditable) return;
                  ref.read(autoSubmitControllerProvider.notifier).submit(
                    documentId: doc.id,
                    type: type,
                    fields: fields,
                    isEdited: isEdited,
                    onSuccess: (newDoc) {
                      onSubmitSuccess?.call();
                      ref.read(autoSubmitControllerProvider.notifier).reset();
                      _showSuccess(context, newDoc.referenceNumber);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context, String refNo) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Document Submitted'),
        content: Text(
          'Reference number: $refNo\n\nYour document has been submitted for checker review.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

}
