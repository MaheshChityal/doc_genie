import 'dart:math';

import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/custom_exception.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/feature/maker/model/manual_scan_model.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:file_picker/file_picker.dart';

/// Data layer for the Manual Upload flow — scan (OCR) then submit.
class ManualRepository {
  final AppClient _client = AppClient.instance;

  static const bool useMock = true;

  /// Uploads the file and returns the extracted fields ([ManualScanModel]).
  Future<void> scan({
    required PlatformFile file,
    required Function(ManualScanModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final types = TransactionType.values;
      final type = types[Random().nextInt(types.length)];
      onSuccess(
        ManualScanModel(
          fileName: file.name,
          type: type,
          fields: _mockFields(type),
        ),
      );
      return;
    }

    try {
      final bytes = file.bytes;
      if (bytes == null) {
        onfailure(CustomException('Could not read file bytes.'));
        return;
      }
      final response = await _client.request(
        requestType: RequestType.postMultiPart,
        url: ApiConstants.manualScan,
        parameter: {'file': bytes},
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        onSuccess(
          ManualScanModel.fromJson(
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

  /// Submits the reviewed manual document. Returns the created reference number.
  Future<void> submitDocument({
    required TransactionType type,
    required Map<String, String> fields,
    required String isEdited,
    String remark = '',
    String fileName = '',
    required Function(String referenceNumber) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onSuccess('DG-${DateTime.now().year}-${Random().nextInt(9000) + 1000}');
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.post,
        url: ApiConstants.makerDocs,
        parameter: {
          'source': 1,
          'transactionType': type.label,
          'isEdited': isEdited,
          'remark': remark,
          'fileName': fileName,
          'fields': fields,
        },
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        final data = response.data;
        final root = (data is Map && data['data'] is Map) ? data['data'] : data;
        final refNo =
            (root is Map ? (root['referenceNumber'] ?? root['id'] ?? '') : '')
                .toString();
        onSuccess(refNo);
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
          'remitterName': 'Acme Corp Ltd',
          'remitterAddress': '12 MG Road, Mumbai 400001',
          'beneficiaryAddress': 'Plot 45, Pune 411001',
          'purposeOfTransfer': 'Vendor Payment',
          'mobileNumber': '9800000001',
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
          'remitterName': 'John Doe Enterprises',
          'remitterAddress': '9 Park Street, Kolkata 700016',
          'beneficiaryAddress': 'A-2, Sector 5, Noida 201301',
          'purposeOfTransfer': 'Salary',
          'mobileNumber': '9800000002',
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
          'remitterName': 'Internal Dept',
          'remitterAddress': 'HO, Fort, Mumbai 400001',
          'beneficiaryAddress': 'Branch 12, Delhi 110001',
          'purposeOfTransfer': 'Internal Transfer',
          'mobileNumber': '9800000003',
          'beneAccount': 'SA-002-12345',
          'amount': '10000',
          'narration': 'Internal transfer',
          'chequeBasedTransaction': 'Without Cheque',
          'chequeNumber': '',
          'chequeDate': '',
        };
    }
  }
}
