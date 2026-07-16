import 'package:doc_genie/constants/color_const.dart';
import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle heading = TextStyle(
    fontSize: 30,
    height: 1.05,
    letterSpacing: -0.9,
    fontWeight: FontWeight.w800,
    color: ColorConstants.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 1.15,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w700,
    color: ColorConstants.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.5,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: ColorConstants.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: ColorConstants.textSecondary,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 11.5,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w800,
    color: ColorConstants.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: Colors.white,
  );
}
