import 'dart:convert';
import 'dart:typed_data';

import 'package:doc_genie/feature/maker/model/scan_models.dart';

/// A row in the Auto Scan documents table (parsed from the flat auto-scan
/// list API). Carries the full transaction [fields] so the detail dialog can
/// reuse [TransactionForm].
class AutoDocModel {
  const AutoDocModel({
    required this.id,
    required this.fileName,
    required this.referenceNumber,
    required this.transactionType,
    required this.status,
    required this.submittedAt,
    required this.makerBy,
    this.fileBytes,
    this.fields = const {},
  });

  final String id;
  final String fileName;
  final String referenceNumber;
  final String transactionType;
  final String status;
  final String submittedAt;
  final String makerBy;

  /// Raw bytes of the scanned source document (PDF) for the preview pane.
  final Uint8List? fileBytes;
  final Map<String, String> fields;

  /// Parses the flat auto-scan API object (all fields at the root level).
  factory AutoDocModel.fromJson(Map<String, dynamic> json) {
    final fields = autoScanFields(json);
    final chequeDate = fields['chequeDate'] ?? '';
    return AutoDocModel(
      id: (json['id'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      referenceNumber: 'DG-${json['id']}',
      transactionType: fields['receiptMode'] ?? '',
      status: (json['status'] ?? 'Pending').toString(),
      submittedAt: chequeDate.isNotEmpty ? chequeDate : todayFormatted(),
      makerBy: (json['makerBy'] ?? json['submittedBy'] ?? '').toString(),
      fileBytes: _decodeBytes(
        json['fileBytes'] ?? json['file'] ?? json['fileBase64'] ?? json['document'],
      ),
      fields: fields,
    );
  }

  /// Accepts a base64 String or a raw `List<int>` of the document bytes.
  static Uint8List? _decodeBytes(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is String) {
        if (raw.isEmpty) return null;
        // Tolerate data URLs like "data:application/pdf;base64,....".
        final b64 = raw.contains(',') ? raw.split(',').last : raw;
        return base64Decode(b64);
      }
      if (raw is List) return Uint8List.fromList(raw.cast<int>());
    } catch (_) {}
    return null;
  }

  AutoDocModel copyWith({String? status}) => AutoDocModel(
        id: id,
        fileName: fileName,
        referenceNumber: referenceNumber,
        transactionType: transactionType,
        status: status ?? this.status,
        submittedAt: submittedAt,
        makerBy: makerBy,
        fileBytes: fileBytes,
        fields: fields,
      );
}
