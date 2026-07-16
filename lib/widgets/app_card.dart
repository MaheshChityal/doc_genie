import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? ColorConstants.surface)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor ?? ColorConstants.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141C2730),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.value,
    required this.label,
    this.highlighted = false,
    this.color,
  });

  final String value;
  final String label;
  final bool highlighted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c =
        color ??
        (highlighted
            ? ColorConstants.successColor
            : ColorConstants.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: highlighted
            ? ColorConstants.successColor.withValues(alpha: 0.12)
            : ColorConstants.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? ColorConstants.successColor.withValues(alpha: 0.22)
              : ColorConstants.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: ColorConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
