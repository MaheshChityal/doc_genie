import 'dart:typed_data';

import 'package:doc_genie/constants/text_styles.dart';
import 'package:flutter/material.dart';

/// Non-web fallback — inline PDF rendering is only wired for the web build.
Widget buildPdfPreview(Uint8List bytes) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'PDF preview is available on the web build.',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ),
    );
