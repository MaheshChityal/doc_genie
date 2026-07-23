import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/custom_exception.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/feature/report/model/report_model.dart';

class ReportRepository {
  final AppClient _client = AppClient.instance;

  static const bool useMock = true;

  Future<void> fetchReport({
    required void Function(ReportModel) onSuccess,
    required void Function(CustomException) onFailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      onSuccess(_mockReport);
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.getWithToken,
        url: ApiConstants.report,
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        onSuccess(
          ReportModel.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      } else {
        onFailure(getCustomException(response.data));
      }
    } catch (ex) {
      onFailure(getCustomException(ex));
    }
  }
}

const _mockReport = ReportModel(
  stats: ReportStats(
    total: 128,
    pending: 14,
    approved: 98,
    rejected: 16,
    rtgs: 54,
    neft: 48,
    fundTransfer: 26,
  ),
  documents: [
    ReportDoc(
      id: '1',
      referenceNumber: 'DG-2026-AUTO001',
      transactionType: 'RTGS',
      status: 'Approved',
      date: '23 Jul 2026',
      submittedBy: 'M001',
      fileName: 'scan_001.pdf',
    ),
    ReportDoc(
      id: '2',
      referenceNumber: 'DG-2026-AUTO002',
      transactionType: 'NEFT',
      status: 'Pending',
      date: '23 Jul 2026',
      submittedBy: 'M002',
      fileName: 'doc_A002.pdf',
    ),
    ReportDoc(
      id: '3',
      referenceNumber: 'DG-2026-AUTO003',
      transactionType: 'Fund Transfer',
      status: 'Rejected',
      date: '22 Jul 2026',
      submittedBy: 'M001',
      fileName: 'scan_003.pdf',
    ),
    ReportDoc(
      id: '4',
      referenceNumber: 'DG-2026-AUTO004',
      transactionType: 'RTGS',
      status: 'Approved',
      date: '22 Jul 2026',
      submittedBy: 'M003',
      fileName: 'doc_004.pdf',
    ),
    ReportDoc(
      id: '5',
      referenceNumber: 'DG-2026-AUTO005',
      transactionType: 'NEFT',
      status: 'Approved',
      date: '21 Jul 2026',
      submittedBy: 'M002',
      fileName: 'scan_005.pdf',
    ),
    ReportDoc(
      id: '6',
      referenceNumber: 'DG-2026-AUTO006',
      transactionType: 'RTGS',
      status: 'Pending',
      date: '21 Jul 2026',
      submittedBy: 'M001',
      fileName: 'doc_006.pdf',
    ),
    ReportDoc(
      id: '7',
      referenceNumber: 'DG-2026-AUTO007',
      transactionType: 'Fund Transfer',
      status: 'Approved',
      date: '20 Jul 2026',
      submittedBy: 'M003',
      fileName: 'scan_007.pdf',
    ),
    ReportDoc(
      id: '8',
      referenceNumber: 'DG-2026-AUTO008',
      transactionType: 'NEFT',
      status: 'Rejected',
      date: '20 Jul 2026',
      submittedBy: 'M002',
      fileName: 'doc_008.pdf',
    ),
    ReportDoc(
      id: '9',
      referenceNumber: 'DG-2026-AUTO009',
      transactionType: 'RTGS',
      status: 'Approved',
      date: '19 Jul 2026',
      submittedBy: 'M001',
      fileName: 'scan_009.pdf',
    ),
    ReportDoc(
      id: '10',
      referenceNumber: 'DG-2026-AUTO010',
      transactionType: 'Fund Transfer',
      status: 'Pending',
      date: '19 Jul 2026',
      submittedBy: 'M003',
      fileName: 'doc_010.pdf',
    ),
  ],
);
