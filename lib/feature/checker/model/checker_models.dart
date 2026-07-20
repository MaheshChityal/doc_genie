import 'dart:convert';
import 'dart:typed_data';

class CheckerDocModel {
  const CheckerDocModel({
    required this.id,
    required this.referenceNumber,
    required this.submittedBy,
    required this.transactionType,
    required this.status,
    required this.date,
    this.fileName = '',
    this.fileBytes,
    this.fields = const {},
  });

  final String id;
  final String referenceNumber;
  final String submittedBy;
  final String transactionType;
  final String status;
  final String date;
  final String fileName;

  /// Raw bytes of the scanned source document (PDF) for the preview pane.
  final Uint8List? fileBytes;
  final Map<String, String> fields;

  factory CheckerDocModel.fromJson(Map<String, dynamic> json) =>
      CheckerDocModel(
        id: (json['id'] ?? '').toString(),
        referenceNumber: (json['referenceNumber'] ?? '').toString(),
        submittedBy: (json['submittedBy'] ?? '').toString(),
        transactionType: (json['transactionType'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        fileName: (json['fileName'] ?? '').toString(),
        fileBytes: _decodeBytes(
          json['fileBytes'] ?? json['file'] ?? json['fileBase64'],
        ),
        fields: (json['fields'] is Map)
            ? Map<String, String>.from(
                (json['fields'] as Map).map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              )
            : {},
      );

  /// Accepts a base64 String or a raw `List<int>` of the document bytes.
  static Uint8List? _decodeBytes(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is String) {
        if (raw.isEmpty) return null;
        final b64 = raw.contains(',') ? raw.split(',').last : raw;
        return base64Decode(b64);
      }
      if (raw is List) return Uint8List.fromList(raw.cast<int>());
    } catch (_) {}
    return null;
  }

  CheckerDocModel copyWith({String? status}) => CheckerDocModel(
    id: id,
    referenceNumber: referenceNumber,
    submittedBy: submittedBy,
    transactionType: transactionType,
    status: status ?? this.status,
    date: date,
    fileName: fileName,
    fileBytes: fileBytes,
    fields: fields,
  );
}
