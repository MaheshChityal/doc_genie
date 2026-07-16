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
/// Keys match the API field names exactly so pre-filling works automatically.
const rtgsFields = <(String, String, bool)>[
  ('remitterAccountType', 'Remitter Account Type (CASA a/c/ GL)', false),
  ('remitterAccountNumber', 'Remitter Account Number', false),
  ('receiptMode', 'Receipt Mode', false),
  ('chequeBasedTransaction', 'Cheque Based Transaction (With/Without Cheque)', false),
  ('chequeNumber', 'Cheque Number', true),
  ('chequeDate', 'Cheque Date', true),
  ('amount', 'Amount', false),
  ('amountInWords', 'Amount in Words', false),
  ('sendingInformation', 'Sending Information (SMS/Email/Default)', false),
  ('instructionPriority', 'Instruction Priority (High/Normal)', false),
  ('beneficiaryIFSCCode', 'Bene IFSC Code', false),
  ('beneficiaryAccountNumber', 'Bene Account Number', false),
  ('beneficiaryName', 'Bene Name', false),
  ('beneficiaryAccountTypeCode', 'Bene Account Type', false),
  ('leiCode', 'LEI Code (if Amount ≥ 50 Cr)', true),
  ('narration', 'Narration', false),
  ('emailId', 'Email ID', false),
];

const neftFields = <(String, String, bool)>[
  ('remitterAccountType', 'Remitter Account Type (CASA a/c/ GL)', false),
  ('remitterAccountNumber', 'Remitter Account Number', false),
  ('receiptMode', 'Receipt Mode', false),
  ('chequeBasedTransaction', 'Cheque Based Transaction (With/Without Cheque)', false),
  ('chequeNumber', 'Cheque Number', true),
  ('chequeDate', 'Cheque Date', true),
  ('amount', 'Amount', false),
  ('amountInWords', 'Amount in Words', false),
  ('sendingInformation', 'Sending Information (SMS/Email/Default)', false),
  ('beneficiaryIFSCCode', 'Bene IFSC Code', false),
  ('beneficiaryAccountNumber', 'Bene Account Number', false),
  ('beneficiaryName', 'Bene Name', false),
  ('beneficiaryAccountTypeCode', 'Bene Account Type (Saving/OD/CC/Loan/NRE/FCRA)', false),
  ('leiCode', 'LEI Code (if Amount ≥ 50 Cr)', true),
  ('narration', 'Narration', false),
  ('emailId', 'Email ID', false),
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

  /// Parses the auto scan list API response — a flat object where all
  /// document fields sit at the root level (no nested `fields` key).
  factory DocumentModel.fromAutoScanJson(Map<String, dynamic> json) {
    final receiptMode = (json['receiptMode'] ?? '').toString();

    // Parse ISO chequeDate to a readable string
    String chequeDate = '';
    final raw = json['chequeDate'];
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(raw.toString());
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        chequeDate = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        chequeDate = raw.toString();
      }
    }

    final fields = <String, String>{
      'remitterAccountType':
          (json['remitterAccountType'] ?? '').toString(),
      'remitterAccountNumber':
          (json['remitterAccountNumber'] ?? '').toString(),
      'receiptMode': receiptMode,
      'chequeBasedTransaction':
          (json['chequeBasedTransaction'] ?? '').toString(),
      'chequeNumber': (json['chequeNumber'] ?? '').toString(),
      'chequeDate': chequeDate,
      'amount': (json['amount'] ?? '').toString(),
      'amountInWords': (json['amountInWords'] ?? '').toString(),
      'sendingInformation': (json['sendingInformation'] ?? '').toString(),
      'instructionPriority': (json['instructionPriority'] ?? '').toString(),
      'beneficiaryIFSCCode': (json['beneficiaryIFSCCode'] ?? '').toString(),
      'beneficiaryAccountNumber':
          (json['beneficiaryAccountNumber'] ?? '').toString(),
      'beneficiaryName': (json['beneficiaryName'] ?? '').toString(),
      'beneficiaryAccountTypeCode':
          (json['beneficiaryAccountTypeCode'] ?? '').toString(),
      'leiCode': (json['leiCode'] ?? '').toString(),
      'narration': (json['narration'] ?? '').toString(),
      'emailId': (json['emailId'] ?? '').toString(),
    };

    return DocumentModel(
      id: (json['id'] ?? '').toString(),
      referenceNumber: 'DG-${json['id']}',
      transactionType: receiptMode,
      status: 'Pending',
      submittedAt: chequeDate.isNotEmpty ? chequeDate : _today(),
      fields: fields,
    );
  }

  DocumentModel copyWith({String? status}) => DocumentModel(
    id: id,
    referenceNumber: referenceNumber,
    transactionType: transactionType,
    status: status ?? this.status,
    submittedAt: submittedAt,
    fields: fields,
  );

  static String _today() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
