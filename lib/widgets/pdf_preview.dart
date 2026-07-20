import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'pdf_preview_stub.dart' if (dart.library.html) 'pdf_preview_web.dart'
    as impl;

/// Renders PDF [bytes] inline. On web this is a native `<iframe>` fed a blob
/// URL (no dependency); on other platforms it shows a fallback message.
Widget buildPdfPreview(Uint8List bytes) => impl.buildPdfPreview(bytes);
