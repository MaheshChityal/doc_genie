import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:flutter/material.dart';

/// A styled confirmation dialog with a success icon, message, and an optional
/// highlighted reference number.
Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? referenceNumber,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ColorConstants.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ColorConstants.successColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: ColorConstants.successColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              if (referenceNumber != null && referenceNumber.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ColorConstants.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tag_rounded,
                        size: 15,
                        color: ColorConstants.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        referenceNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: ColorConstants.primaryColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
