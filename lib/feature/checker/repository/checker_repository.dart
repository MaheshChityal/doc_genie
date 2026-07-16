import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/custom_exception.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/feature/checker/model/checker_models.dart';

class CheckerRepository {
  final AppClient _client = AppClient.instance;

  static const bool useMock = true;

  Future<void> fetchDocuments({
    required Function(List<CheckerDocModel>) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      onSuccess(_mockDocs());
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.getWithToken,
        url: ApiConstants.checkerDocs,
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        final list = (response.data as List? ?? [])
            .whereType<Map>()
            .map((e) => CheckerDocModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        onSuccess(list);
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }

  Future<String?> decide(String id, String decision) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return null;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.postWithToken,
        url: ApiConstants.checkerDecide(id),
        parameter: {'decision': decision},
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return null;
      return 'Request failed';
    } catch (ex) {
      return getCustomException(ex).message;
    }
  }

  static List<CheckerDocModel> _mockDocs() => [
    CheckerDocModel(
      id: 'CHK001',
      referenceNumber: 'DG-2026-AUTO001',
      submittedBy: 'M001',
      transactionType: 'RTGS',
      status: 'Pending',
      date: '16 Jul 2026',
      fields: {
        'remitterAccountType': 'CASA',
        'remitterAccountNumber': '12345678901',
        'receiptMode': 'Email',
        'chequeNumber': '',
        'chequeDate': '',
        'amount': '250000',
        'sendingInfo': 'SMS',
        'instructionPriority': 'High',
        'beneIfscCode': 'HDFC0001234',
        'beneAccountNumber': '98765432101',
        'beneName': 'Acme Corp Ltd',
        'leiCode': '',
        'narration': 'Vendor payment Q3',
      },
    ),
    CheckerDocModel(
      id: 'CHK002',
      referenceNumber: 'DG-2026-AUTO002',
      submittedBy: 'M002',
      transactionType: 'NEFT',
      status: 'Pending',
      date: '16 Jul 2026',
      fields: {
        'remitterAccountType': 'CASA',
        'remitterAccountNumber': '11223344556',
        'receiptMode': 'Original',
        'chequeNumber': '',
        'chequeDate': '',
        'amount': '75000',
        'sendingInfo': 'Email',
        'ifscCode': 'SBIN0012345',
        'beneIfscCode': 'SBIN0012345',
        'beneAccountNumber': '55667788990',
        'beneName': 'John Doe',
        'beneAccountTypeCode': 'Saving',
        'narration': 'Salary July 2026',
      },
    ),
    CheckerDocModel(
      id: 'CHK003',
      referenceNumber: 'DG-2026-MAN001',
      submittedBy: 'M001',
      transactionType: 'Fund Transfer',
      status: 'Approved',
      date: '15 Jul 2026',
      fields: {
        'remitterAccount': 'CA-001-98765',
        'beneAccount': 'SA-002-12345',
        'amount': '10000',
        'narration': 'Internal transfer',
        'chequeBasedTransaction': 'Without Cheque',
        'chequeNumber': '',
        'chequeDate': '',
      },
    ),
    CheckerDocModel(
      id: 'CHK004',
      referenceNumber: 'DG-2026-MAN002',
      submittedBy: 'M003',
      transactionType: 'RTGS',
      status: 'Rejected',
      date: '14 Jul 2026',
      fields: {
        'remitterAccountType': 'GL',
        'remitterAccountNumber': '99887766554',
        'receiptMode': 'Original',
        'chequeNumber': '',
        'chequeDate': '',
        'amount': '1000000',
        'sendingInfo': 'Default',
        'instructionPriority': 'Normal',
        'beneIfscCode': 'ICIC0004567',
        'beneAccountNumber': '12398765432',
        'beneName': 'Tech Supplies Inc',
        'leiCode': '',
        'narration': 'Equipment purchase',
      },
    ),
  ];
}
