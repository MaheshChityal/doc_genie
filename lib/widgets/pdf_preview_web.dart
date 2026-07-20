// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web implementation — renders the PDF [bytes] in a native `<iframe>` via a
/// blob URL. `toolbar=0&navpanes=0` hides Chrome's PDF toolbar (download /
/// annotate / drive / print) and the thumbnail sidebar; zoom is via
/// Ctrl+scroll / trackpad pinch. The src is set once (no reload).
Widget buildPdfPreview(Uint8List bytes) => _PdfIframe(bytes: bytes);

class _PdfIframe extends StatefulWidget {
  const _PdfIframe({required this.bytes});

  final Uint8List bytes;

  @override
  State<_PdfIframe> createState() => _PdfIframeState();
}

class _PdfIframeState extends State<_PdfIframe> {
  late final String _viewType;
  String? _objectUrl;

  @override
  void initState() {
    super.initState();
    final blob = html.Blob(<Object>[widget.bytes], 'application/pdf');
    _objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final src = '$_objectUrl#toolbar=0&navpanes=0';
    _viewType = 'pdf-preview-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  void dispose() {
    final url = _objectUrl;
    if (url != null) html.Url.revokeObjectUrl(url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
