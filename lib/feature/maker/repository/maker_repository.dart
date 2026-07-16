import 'dart:math';

import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/custom_exception.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:file_picker/file_picker.dart';

class MakerRepository {
  final AppClient _client = AppClient.instance;

  static const bool useMock = true;

  Future<void> autoScan({
    required PlatformFile file,
    required Function(ScanResultModel) onSuccess,
    required Function(CustomException) onfailure,
  }) => _scan(
    file: file,
    url: ApiConstants.autoScan,
    onSuccess: onSuccess,
    onfailure: onfailure,
  );

  Future<void> manualScan({
    required PlatformFile file,
    required Function(ScanResultModel) onSuccess,
    required Function(CustomException) onfailure,
  }) => _scan(
    file: file,
    url: ApiConstants.manualScan,
    onSuccess: onSuccess,
    onfailure: onfailure,
  );

  Future<void> _scan({
    required PlatformFile file,
    required String url,
    required Function(ScanResultModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final types = TransactionType.values;
      final type = types[Random().nextInt(types.length)];
      final fields = _mockFields(type);
      final docId = 'DOC-${DateTime.now().millisecondsSinceEpoch}';
      onSuccess(ScanResultModel(documentId: docId, type: type, fields: fields));
      return;
    }

    try {
      final bytes = file.bytes;
      if (bytes == null) {
        onfailure(CustomException('Could not read file bytes.'));
        return;
      }
      final formData = {'file': bytes};
      final response = await _client.request(
        requestType: RequestType.postMultiPartWithToken,
        url: url,
        parameter: formData,
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        onSuccess(
          ScanResultModel.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }

  Future<void> submitDocument({
    required String documentId,
    required TransactionType type,
    required Map<String, String> fields,
    required String isEdited,
    String remark = '',
    required Function(DocumentModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final refNo =
          'DG-${DateTime.now().year}-${Random().nextInt(9000) + 1000}';
      onSuccess(
        DocumentModel(
          id: documentId,
          referenceNumber: refNo,
          transactionType: type.label,
          status: 'Pending',
          submittedAt: _today(),
          fields: fields,
        ),
      );
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.postWithToken,
        url: ApiConstants.makerDocs,
        parameter: {
          'documentId': documentId,
          'transactionType': type.label,
          'isEdited': isEdited,
          'remark': remark,
          'fields': fields,
        },
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        onSuccess(
          DocumentModel.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }

  /// Submits an auto-scan document using the flat payload format the API expects.
  Future<void> submitAutoScanDocument({
    required String documentId,
    required TransactionType type,
    required Map<String, String> fields,
    String remark = '',
    required Function(DocumentModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    final payload = <String, dynamic>{
      'remitterAccountType': fields['remitterAccountType'] ?? '',
      'remitterAccountNumber': fields['remitterAccountNumber'] ?? '',
      'receiptMode': fields['receiptMode'] ?? '',
      'chequeBasedTransaction': fields['chequeBasedTransaction'] ?? '',
      'chequeNumber': fields['chequeNumber'] ?? '',
      'chequeDate': _toIsoDate(fields['chequeDate'] ?? ''),
      'amount':
          double.tryParse((fields['amount'] ?? '').replaceAll(',', '')) ?? 0,
      'amountInWords': fields['amountInWords'] ?? '',
      'sendingInformation': fields['sendingInformation'] ?? '',
      'instructionPriority': fields['instructionPriority'] ?? '',
      'beneficiaryIFSCCode': fields['beneficiaryIFSCCode'] ?? '',
      'beneficiaryAccountNumber': fields['beneficiaryAccountNumber'] ?? '',
      'beneficiaryName': fields['beneficiaryName'] ?? '',
      'beneficiaryAccountTypeCode': fields['beneficiaryAccountTypeCode'] ?? '',
      'leiCode': fields['leiCode'] ?? '',
      'narration': fields['narration'] ?? '',
      'emailId': fields['emailId'] ?? '',
      'remark': remark,
    };

    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onSuccess(
        DocumentModel(
          id: documentId,
          referenceNumber: 'DG-$documentId',
          transactionType: fields['receiptMode'] ?? type.label,
          status: 'Pending',
          submittedAt: _today(),
          fields: fields,
        ),
      );
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.postWithToken,
        url: ApiConstants.autoScan,
        parameter: payload,
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        onSuccess(
          DocumentModel.fromAutoScanJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }

  /// Converts a human-readable date string ("9 Jul 2026") to ISO format
  /// ("2026-07-09T00:00:00") for the submit API. Falls back to returning the
  /// input unchanged if parsing fails.
  static String _toIsoDate(String formatted) {
    const monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final parts = formatted.trim().split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = monthMap[parts[1]];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return '$year-${month.toString().padLeft(2, '0')}'
            '-${day.toString().padLeft(2, '0')}T00:00:00';
      }
    }
    // Already ISO or unparseable — return as-is
    try {
      final dt = DateTime.parse(formatted);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
          '-${dt.day.toString().padLeft(2, '0')}T00:00:00';
    } catch (_) {
      return formatted;
    }
  }

  Future<void> fetchDocuments({
    required bool isAutoScan,
    required Function(List<DocumentModel>) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      onSuccess(_mockDocList(isAutoScan));
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.getWithToken,
        url: isAutoScan ? ApiConstants.getAuto : ApiConstants.getManual,
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        final list = (response.data as List? ?? [])
            .whereType<Map>()
            .map(
              (e) => isAutoScan
                  ? DocumentModel.fromAutoScanJson(Map<String, dynamic>.from(e))
                  : DocumentModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
        onSuccess(list);
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }

  static Map<String, String> _mockFields(TransactionType type) {
    switch (type) {
      case TransactionType.rtgs:
        return {
          'remitterAccountType': 'CASA',
          'remitterAccountNumber': '57500001929680',
          'receiptMode': 'RTGS',
          'chequeBasedTransaction': 'With Cheque',
          'chequeNumber': '0505',
          'chequeDate': '9 Jul 2026',
          'amount': '250000',
          'amountInWords': 'Two Lakh Fifty Thousand Only',
          'sendingInformation': 'Default',
          'instructionPriority': 'Normal',
          'beneficiaryIFSCCode': 'ICIC0000408',
          'beneficiaryAccountNumber': '040805005064',
          'beneficiaryName': 'Acme Corp Ltd',
          'beneficiaryAccountTypeCode': 'Saving',
          'leiCode': '',
          'narration': 'Vendor payment Q3',
          'emailId': '',
        };
      case TransactionType.neft:
        return {
          'remitterAccountType': 'CASA',
          'remitterAccountNumber': '57511101929510',
          'receiptMode': 'NEFT',
          'chequeBasedTransaction': 'With Cheque',
          'chequeNumber': '000001',
          'chequeDate': '9 Jul 2026',
          'amount': '75000',
          'amountInWords': 'Seventy Five Thousand Only',
          'sendingInformation': 'Default',
          'beneficiaryIFSCCode': 'ICIC0000111',
          'beneficiaryAccountNumber': '55667788990',
          'beneficiaryName': 'John Doe',
          'beneficiaryAccountTypeCode': 'Saving',
          'leiCode': '',
          'narration': 'Salary July 2026',
          'emailId': '',
        };
      case TransactionType.fundTransfer:
        return {
          'remitterAccount': 'CA-001-98765',
          'beneAccount': 'SA-002-12345',
          'amount': '10000',
          'narration': 'Internal transfer',
          'chequeBasedTransaction': 'Without Cheque',
          'chequeNumber': '',
          'chequeDate': '',
        };
    }
  }

  static List<DocumentModel> _mockDocList(bool isAutoScan) {
    // A larger dataset so search + pagination are demonstrable in mock mode.
    const beneNames = [
      'FISCHER MARINE AND OFFSHORE PRIVATE LIMITED',
      'FISCHER OFFSHORE PRIVATE LIMITED',
      'Acme Corp Ltd',
      'John Doe',
      'Tech Supplies Inc',
      'Blue Ocean Traders',
      'Sunrise Exports LLP',
      'Meridian Logistics Pvt Ltd',
    ];
    const statuses = ['Pending', 'Approved', 'Rejected'];
    const modes = ['RTGS', 'NEFT'];

    if (isAutoScan) {
      // Mock matches the real (flat) API response structure.
      return List<DocumentModel>.generate(64, (i) {
        final id = i + 1;
        final mode = modes[i % modes.length];
        return DocumentModel.fromAutoScanJson({
          'id': id,
          'remitterAccountType': '',
          'remitterAccountNumber': '5750000${1929680 + id}',
          'receiptMode': mode,
          'chequeBasedTransaction': 'With Cheque',
          'chequeNumber': '0${500 + id}',
          'chequeDate': '2026-07-09T00:00:00',
          'amount': 100000 + id * 1375,
          'amountInWords': 'Amount in words for doc $id',
          'sendingInformation': 'Default',
          'instructionPriority': 'Normal',
          'beneficiaryIFSCCode': 'ICIC000${400 + id}',
          'beneficiaryAccountNumber': '0408050${5000 + id}',
          'beneficiaryName': beneNames[i % beneNames.length],
          'beneficiaryAccountTypeCode': 'Saving',
          'leiCode': '',
          'narration': 'FUND TRANSFER',
          'emailId': '',
        }).copyWith(status: statuses[i % statuses.length]);
      });
    }

    // Manual scan mock
    const types = ['RTGS', 'NEFT', 'Fund Transfer'];
    return List<DocumentModel>.generate(48, (i) {
      final n = (i + 1).toString().padLeft(3, '0');
      return DocumentModel(
        id: 'MAN$n',
        referenceNumber: 'DG-2026-MAN$n',
        transactionType: types[i % types.length],
        status: statuses[i % statuses.length],
        submittedAt: '${(i % 28) + 1} Jul 2026',
      );
    });
  }

  static String _today() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
