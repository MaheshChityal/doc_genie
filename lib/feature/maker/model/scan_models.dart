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

/// A titled group of fields shown together in the form.
class FieldSection {
  const FieldSection(this.title, this.fields);

  final String title;

  /// Each entry: (key, label, optional). Keys match the API field names.
  final List<(String, String, bool)> fields;
}

const _remitterCommon = <(String, String, bool)>[
  ('remitterAccountType', 'Remitter Account Type (CASA a/c/ GL)', false),
  ('remitterAccountNumber', 'Remitter Account Number', false),
  ('remitterName', 'Remitter Name', false),
  ('remitterAddress', 'Remitter Address', true),
  ('mobileNumber', 'Mobile Number', true),
];

const _rtgsSections = <FieldSection>[
  FieldSection('Remitter Details', _remitterCommon),
  FieldSection('Beneficiary Details', [
    ('beneficiaryName', 'Bene Name', false),
    ('beneficiaryAccountNumber', 'Bene Account Number', false),
    ('beneficiaryIFSCCode', 'Bene IFSC Code', false),
    ('beneficiaryAccountTypeCode', 'Bene Account Type', false),
    ('beneficiaryAddress', 'Beneficiary Address', true),
  ]),
  FieldSection('Transaction Details', [
    ('receiptMode', 'Receipt Mode', false),
    ('amount', 'Amount', false),
    ('amountInWords', 'Amount in Words', false),
    ('instructionPriority', 'Instruction Priority (High/Normal)', false),
    ('leiCode', 'LEI Code (if Amount ≥ 50 Cr)', true),
    ('purposeOfTransfer', 'Purpose of Transfer', false),
    ('narration', 'Narration', false),
    ('emailId', 'Email ID', false),
  ]),
];

const _neftSections = <FieldSection>[
  FieldSection('Remitter Details', _remitterCommon),
  FieldSection('Beneficiary Details', [
    ('beneficiaryName', 'Bene Name', false),
    ('beneficiaryAccountNumber', 'Bene Account Number', false),
    ('beneficiaryIFSCCode', 'Bene IFSC Code', false),
    ('beneficiaryAccountTypeCode', 'Bene Account Type (Saving/OD/CC/Loan/NRE/FCRA)', false),
    ('beneficiaryAddress', 'Beneficiary Address', true),
  ]),
  FieldSection('Transaction Details', [
    ('receiptMode', 'Receipt Mode', false),
    ('amount', 'Amount', false),
    ('amountInWords', 'Amount in Words', false),
    ('leiCode', 'LEI Code (if Amount ≥ 50 Cr)', true),
    ('purposeOfTransfer', 'Purpose of Transfer', false),
    ('narration', 'Narration', false),
    ('emailId', 'Email ID', false),
  ]),
];

const _fundTransferSections = <FieldSection>[
  FieldSection('Remitter Details', [
    ('remitterAccount', 'Remitter Account', false),
    ('remitterName', 'Remitter Name', false),
    ('remitterAddress', 'Remitter Address', true),
    ('mobileNumber', 'Mobile Number', true),
  ]),
  FieldSection('Beneficiary Details', [
    ('beneAccount', 'Bene Account', false),
    ('beneficiaryAddress', 'Beneficiary Address', true),
  ]),
  FieldSection('Transaction Details', [
    ('amount', 'Amount', false),
    ('purposeOfTransfer', 'Purpose of Transfer', false),
    ('narration', 'Narration', false),
  ]),
];

List<FieldSection> sectionsForType(TransactionType type) {
  switch (type) {
    case TransactionType.rtgs:
      return _rtgsSections;
    case TransactionType.neft:
      return _neftSections;
    case TransactionType.fundTransfer:
      return _fundTransferSections;
  }
}

/// Flat list of all fields for [type] (across every section).
List<(String, String, bool)> fieldsForType(TransactionType type) =>
    sectionsForType(type).expand((s) => s.fields).toList();

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "17 Jul 2026" for the current date.
String todayFormatted() {
  final now = DateTime.now();
  return '${now.day} ${_months[now.month - 1]} ${now.year}';
}

/// Converts an ISO date string ("2026-07-09T00:00:00") to "9 Jul 2026".
/// Returns the input unchanged (or empty) if it cannot be parsed.
String isoToReadable(dynamic raw) {
  if (raw == null || raw.toString().isEmpty) return '';
  try {
    final dt = DateTime.parse(raw.toString());
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return raw.toString();
  }
}

/// Extracts the flat auto-scan transaction fields from a root-level JSON object.
Map<String, String> autoScanFields(Map<String, dynamic> json) => {
  'remitterAccountType': (json['remitterAccountType'] ?? '').toString(),
  'remitterAccountNumber': (json['remitterAccountNumber'] ?? '').toString(),
  'remitterName': (json['remitterName'] ?? '').toString(),
  'remitterAddress': (json['remitterAddress'] ?? '').toString(),
  'mobileNumber': (json['mobileNumber'] ?? '').toString(),
  'receiptMode': (json['receiptMode'] ?? '').toString(),
  'chequeBasedTransaction': (json['chequeBasedTransaction'] ?? '').toString(),
  'chequeNumber': (json['chequeNumber'] ?? '').toString(),
  'chequeDate': isoToReadable(json['chequeDate']),
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
  'beneficiaryAddress': (json['beneficiaryAddress'] ?? '').toString(),
  'leiCode': (json['leiCode'] ?? '').toString(),
  'purposeOfTransfer': (json['purposeOfTransfer'] ?? '').toString(),
  'narration': (json['narration'] ?? '').toString(),
  'emailId': (json['emailId'] ?? '').toString(),
};
