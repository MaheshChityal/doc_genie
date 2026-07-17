import 'package:doc_genie/feature/maker/model/scan_models.dart';

/// Response returned after uploading a document on the Manual tab.
///
/// Shaped like the auto get-API response but WITHOUT an `id` (the document is
/// only created once the maker submits). Used to pre-fill [TransactionForm].
class ManualScanModel {
  const ManualScanModel({
    required this.fileName,
    required this.type,
    required this.fields,
  });

  final String fileName;
  final TransactionType type;
  final Map<String, String> fields;

  factory ManualScanModel.fromJson(Map<String, dynamic> json) {
    final fields = autoScanFields(json);
    final typeStr =
        (json['transactionType'] ?? json['receiptMode'] ?? 'rtgs').toString();
    return ManualScanModel(
      fileName: (json['fileName'] ?? '').toString(),
      type: TransactionTypeX.fromString(typeStr),
      fields: fields,
    );
  }
}
