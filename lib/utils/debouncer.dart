import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  bool get isActive => _timer?.isActive ?? false;

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
