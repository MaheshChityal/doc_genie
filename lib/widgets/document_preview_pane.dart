import 'dart:typed_data';

import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/widgets/pdf_preview.dart';
import 'package:flutter/material.dart';

/// Left-pane document preview shared by the maker and checker detail dialogs.
/// Renders the scanned PDF from [fileBytes] when present; otherwise a
/// placeholder.
class DocumentPreviewPane extends StatelessWidget {
  const DocumentPreviewPane({
    super.key,
    required this.fileName,
    this.fileBytes,
  });

  final String fileName;
  final Uint8List? fileBytes;

  @override
  Widget build(BuildContext context) {
    final hasBytes = fileBytes != null && fileBytes!.isNotEmpty;
    return Container(
      color: ColorConstants.surfaceAlt,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: ColorConstants.errorColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName.isEmpty ? 'Scanned Document' : fileName,
                  style: AppTextStyles.caption.copyWith(
                    color: ColorConstants.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ColorConstants.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasBytes
                  ? buildPdfPreview(fileBytes!)
                  : const _PreviewPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 56,
              color: ColorConstants.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Document Preview',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'The scanned document preview will appear here.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
