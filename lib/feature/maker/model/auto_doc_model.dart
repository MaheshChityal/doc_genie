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
    this.fields = const {},
  });

  final String id;
  final String fileName;
  final String referenceNumber;
  final String transactionType;
  final String status;
  final String submittedAt;
  final String makerBy;
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
      fields: fields,
    );
  }

  AutoDocModel copyWith({String? status}) => AutoDocModel(
        id: id,
        fileName: fileName,
        referenceNumber: referenceNumber,
        transactionType: transactionType,
        status: status ?? this.status,
        submittedAt: submittedAt,
        makerBy: makerBy,
        fields: fields,
      );
}
