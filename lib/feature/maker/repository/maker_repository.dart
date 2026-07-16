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
  }) =>
      _scan(
        file: file,
        url: ApiConstants.autoScan,
        onSuccess: onSuccess,
        onfailure: onfailure,
      );

  Future<void> manualScan({
    required PlatformFile file,
    required Function(ScanResultModel) onSuccess,
    required Function(CustomException) onfailure,
  }) =>
      _scan(
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
    required Function(DocumentModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final refNo = 'DG-${DateTime.now().year}-${Random().nextInt(9000) + 1000}';
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
        url: ApiConstants.makerDocs,
        queryParameters: {'type': isAutoScan ? 'auto' : 'manual'},
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        final list = (response.data as List? ?? [])
            .whereType<Map>()
            .map((e) => DocumentModel.fromJson(Map<String, dynamic>.from(e)))
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
        };
      case TransactionType.neft:
        return {
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
    final prefix = isAutoScan ? 'AUTO' : 'MAN';
    return [
      DocumentModel(
        id: '${prefix}001',
        referenceNumber: 'DG-2026-${prefix}001',
        transactionType: 'RTGS',
        status: 'Approved',
        submittedAt: '14 Jul 2026',
      ),
      DocumentModel(
        id: '${prefix}002',
        referenceNumber: 'DG-2026-${prefix}002',
        transactionType: 'NEFT',
        status: 'Pending',
        submittedAt: '15 Jul 2026',
      ),
      DocumentModel(
        id: '${prefix}003',
        referenceNumber: 'DG-2026-${prefix}003',
        transactionType: 'Fund Transfer',
        status: 'Rejected',
        submittedAt: '16 Jul 2026',
      ),
    ];
  }

  static String _today() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
