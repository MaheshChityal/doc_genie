import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/custom_exception.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/constants/sample_pdf.dart';
import 'package:doc_genie/feature/maker/model/auto_doc_model.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';

/// Data layer for the Auto Scan flow — listing and submitting auto documents.
class AutoRepository {
  final AppClient _client = AppClient.instance;

  static const bool useMock = true;

  Future<void> fetchDocuments({
    required Function(List<AutoDocModel>) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      onSuccess(_mockDocs());
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.getWithToken,
        url: ApiConstants.getAuto,
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        final list = (response.data as List? ?? [])
            .whereType<Map>()
            .map((e) => AutoDocModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        onSuccess(list);
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }

  /// Submits an edited auto-scan document using the flat payload the API wants.
  Future<void> submitAutoScanDocument({
    required String documentId,
    required TransactionType type,
    required Map<String, String> fields,
    String remark = '',
    required Function(AutoDocModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    final payload = <String, dynamic>{
      'id': int.tryParse(documentId) ?? documentId,
      'source': 0,
      'remitterAccountType': fields['remitterAccountType'] ?? '',
      'remitterAccountNumber': fields['remitterAccountNumber'] ?? '',
      'remitterName': fields['remitterName'] ?? '',
      'remitterAddress': fields['remitterAddress'] ?? '',
      'mobileNumber': fields['mobileNumber'] ?? '',
      'receiptMode': fields['receiptMode'] ?? '',
      // 'chequeBasedTransaction': fields['chequeBasedTransaction'] ?? '',
      // 'chequeNumber': fields['chequeNumber'] ?? '',
      // 'chequeDate': _toIsoDate(fields['chequeDate'] ?? ''),
      'amount':
          double.tryParse((fields['amount'] ?? '').replaceAll(',', '')) ?? 0,
      'amountInWords': fields['amountInWords'] ?? '',
      // 'sendingInformation': fields['sendingInformation'] ?? '',
      'instructionPriority': fields['instructionPriority'] ?? '',
      'beneficiaryIFSCCode': fields['beneficiaryIFSCCode'] ?? '',
      'beneficiaryAccountNumber': fields['beneficiaryAccountNumber'] ?? '',
      'beneficiaryName': fields['beneficiaryName'] ?? '',
      'beneficiaryAccountTypeCode': fields['beneficiaryAccountTypeCode'] ?? '',
      'beneficiaryAddress': fields['beneficiaryAddress'] ?? '',
      'leiCode': fields['leiCode'] ?? '',
      'purposeOfTransfer': fields['purposeOfTransfer'] ?? '',
      'narration': fields['narration'] ?? '',
      'emailId': fields['emailId'] ?? '',
      'remark': remark,
    };

    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onSuccess(
        AutoDocModel(
          id: documentId,
          fileName: 'scan_$documentId.pdf',
          referenceNumber: 'DG-$documentId',
          transactionType: fields['receiptMode'] ?? type.label,
          status: 'Pending',
          submittedAt: todayFormatted(),
          makerBy: 'M001',
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
          AutoDocModel.fromJson(
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

  /// "9 Jul 2026" -> "2026-07-09T00:00:00" for the submit API.
  // ignore: unused_element
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
    try {
      final dt = DateTime.parse(formatted);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
          '-${dt.day.toString().padLeft(2, '0')}T00:00:00';
    } catch (_) {
      return formatted;
    }
  }

  static List<AutoDocModel> _mockDocs() {
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

    return List<AutoDocModel>.generate(64, (i) {
      final id = i + 1;
      final mode = modes[i % modes.length];
      return AutoDocModel.fromJson({
        'id': id,
        'fileName': 'scan_${id.toString().padLeft(3, '0')}.pdf',
        'fileBytes': SamplePdf.base64,
        'makerBy': 'M00${(i % 5) + 1}',
        'status': statuses[i % statuses.length],
        'remitterAccountType': '',
        'remitterAccountNumber': '5750000${1929680 + id}',
        'remitterName': 'Remitter $id Pvt Ltd',
        'remitterAddress': '$id, MG Road, Mumbai 400001',
        'mobileNumber': '9${800000000 + id}',
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
        'beneficiaryAddress': 'Plot ${id + 10}, Industrial Area, Pune 411001',
        'leiCode': '',
        'purposeOfTransfer': 'Vendor Payment',
        'narration': 'FUND TRANSFER',
        'emailId': '',
      });
    });
  }
}
