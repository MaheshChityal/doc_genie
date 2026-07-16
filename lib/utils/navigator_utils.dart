import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<T?> navigate<T extends Object?>(BuildContext context, Widget screen) {
  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute(builder: (_) => screen));
}

Future<T?> navigateReplacement<T extends Object?, TO extends Object?>(
  BuildContext context,
  Widget screen,
) {
  return Navigator.of(
    context,
  ).pushReplacement<T, TO>(MaterialPageRoute(builder: (_) => screen));
}

Future<T?> navigateAndRemoveAll<T extends Object?>(
  BuildContext context,
  Widget screen,
) {
  return Navigator.of(context).pushAndRemoveUntil<T>(
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}
