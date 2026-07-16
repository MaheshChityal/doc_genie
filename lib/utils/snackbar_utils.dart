import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:flutter/material.dart';

enum SnackType { info, success, error }

class SnackBarUtils {
  const SnackBarUtils._();

  static void show(
    String message, {
    BuildContext? context,
    SnackType type = SnackType.info,
  }) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;

    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return;

    final color = switch (type) {
      SnackType.success => ColorConstants.successColor,
      SnackType.error => ColorConstants.errorColor,
      SnackType.info => ColorConstants.textPrimary,
    };

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }
}
