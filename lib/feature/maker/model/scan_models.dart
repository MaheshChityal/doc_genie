enum TransactionType { rtgs, neft, fundTransfer }

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.rtgs:
        return 'RTGS';
      case TransactionType.neft:
        return 'NEFT';
      case TransactionType.fundTransfer:
        return 'Fund Transfer';
    }
  }

  static TransactionType fromString(String s) {
    switch (s.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'neft':
        return TransactionType.neft;
      case 'fundtransfer':
        return TransactionType.fundTransfer;
      default:
        return TransactionType.rtgs;
    }
  }
}

/// Ordered field definitions for each transaction type.
/// Each entry: (key, label, optional)
const rtgsFields = <(String, String, bool)>[
  ('remitterAccountType', 'Remitter Account Type (CASA a/c/ GL)', false),
  ('remitterAccountNumber', 'Remitter Account Number', false),
  ('receiptMode', 'Receipt Mode (Email/Original)', false),
  ('chequeNumber', 'Cheque Number', true),
  ('chequeDate', 'Cheque Date', true),
  ('amount', 'Amount', false),
  ('sendingInfo', 'Sending Information (SMS/Email/Default)', false),
  ('instructionPriority', 'Instruction Priority (High/Normal)', false),
  ('beneIfscCode', 'Bene IFSC Code', false),
  ('beneAccountNumber', 'Bene Account Number', false),
  ('beneName', 'Bene Name', false),
  ('leiCode', 'LEI Code (if Amount ≥ 50 Cr)', true),
  ('narration', 'Narration', false),
];

const neftFields = <(String, String, bool)>[
  ('remitterAccountType', 'Remitter Account Type (CASA a/c/ GL)', false),
  ('remitterAccountNumber', 'Remitter Account Number', false),
  ('receiptMode', 'Receipt Mode (Email/Original)', false),
  ('chequeNumber', 'Cheque Number', true),
  ('chequeDate', 'Cheque Date', true),
  ('amount', 'Amount', false),
  ('sendingInfo', 'Sending Information (SMS/Email/Default)', false),
  ('ifscCode', 'IFSC Code', false),
  ('beneIfscCode', 'Bene IFSC Code', false),
  ('beneAccountNumber', 'Bene Account Number', false),
  ('beneName', 'Bene Name', false),
  ('beneAccountTypeCode', 'Bene Account Type (Saving/OD/CC/Loan/NRE/FCRA)', false),
  ('narration', 'Narration', false),
];

const fundTransferFields = <(String, String, bool)>[
  ('remitterAccount', 'Remitter Account', false),
  ('beneAccount', 'Bene Account', false),
  ('amount', 'Amount', false),
  ('narration', 'Narration', false),
  ('chequeBasedTransaction', 'Cheque Based Transaction (With/Without Cheque)', false),
  ('chequeNumber', 'Cheque Number (if cheque-based)', true),
  ('chequeDate', 'Cheque Date', true),
];

List<(String, String, bool)> fieldsForType(TransactionType type) {
  switch (type) {
    case TransactionType.rtgs:
      return rtgsFields;
    case TransactionType.neft:
      return neftFields;
    case TransactionType.fundTransfer:
      return fundTransferFields;
  }
}

class ScanResultModel {
  const ScanResultModel({
    required this.documentId,
    required this.type,
    required this.fields,
  });

  final String documentId;
  final TransactionType type;
  final Map<String, String> fields;

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['transactionType'] ?? 'rtgs').toString();
    return ScanResultModel(
      documentId: (json['documentId'] ?? '').toString(),
      type: TransactionTypeX.fromString(typeStr),
      fields: (json['fields'] is Map)
          ? Map<String, String>.from(
              (json['fields'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : {},
    );
  }
}

class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.referenceNumber,
    required this.transactionType,
    required this.status,
    required this.submittedAt,
    this.fields = const {},
  });

  final String id;
  final String referenceNumber;
  final String transactionType;
  final String status;
  final String submittedAt;
  final Map<String, String> fields;

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    id: (json['id'] ?? '').toString(),
    referenceNumber: (json['referenceNumber'] ?? '').toString(),
    transactionType: (json['transactionType'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    submittedAt: (json['submittedAt'] ?? '').toString(),
    fields: (json['fields'] is Map)
        ? Map<String, String>.from(
            (json['fields'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          )
        : {},
  );

  DocumentModel copyWith({String? status}) => DocumentModel(
    id: id,
    referenceNumber: referenceNumber,
    transactionType: transactionType,
    status: status ?? this.status,
    submittedAt: submittedAt,
    fields: fields,
  );
}
