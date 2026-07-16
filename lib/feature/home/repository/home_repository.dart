import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/custom_exception.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/feature/home/model/home_model.dart';

class HomeRepository {
  final AppClient _client = AppClient.instance;

  static const bool useMock = true;

  Future<void> fetchHomeFeed({
    required Function(HomeModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final mockModel = HomeModel(
        stats: const [
          HomeStat(
            label: 'Total Documents',
            value: '128',
            iconKey: 'docs',
            colorHex: 0xFF183B5B,
          ),
          HomeStat(
            label: 'Pending Review',
            value: '14',
            iconKey: 'pending',
            colorHex: 0xFFE4A11B,
          ),
          HomeStat(
            label: 'Approved Today',
            value: '9',
            iconKey: 'approved',
            colorHex: 0xFF228B5A,
          ),
          HomeStat(
            label: 'Rejected Today',
            value: '2',
            iconKey: 'rejected',
            colorHex: 0xFFDC2626,
          ),
          HomeStat(
            label: 'RTGS',
            value: '54',
            iconKey: 'rtgs',
            colorHex: 0xFF2D74DA,
          ),
          HomeStat(
            label: 'NEFT',
            value: '48',
            iconKey: 'neft',
            colorHex: 0xFF1F7A6A,
          ),
          HomeStat(
            label: 'Fund Transfer',
            value: '26',
            iconKey: 'fund',
            colorHex: 0xFFF47B50,
          ),
        ],
        recentActivity: const [
          RecentActivity(
            id: '1',
            referenceNumber: 'DG-2026-001',
            transactionType: 'RTGS',
            status: 'Approved',
            date: '16 Jul 2026',
          ),
          RecentActivity(
            id: '2',
            referenceNumber: 'DG-2026-002',
            transactionType: 'NEFT',
            status: 'Pending',
            date: '16 Jul 2026',
          ),
          RecentActivity(
            id: '3',
            referenceNumber: 'DG-2026-003',
            transactionType: 'Fund Transfer',
            status: 'Rejected',
            date: '15 Jul 2026',
          ),
          RecentActivity(
            id: '4',
            referenceNumber: 'DG-2026-004',
            transactionType: 'RTGS',
            status: 'Pending',
            date: '15 Jul 2026',
          ),
          RecentActivity(
            id: '5',
            referenceNumber: 'DG-2026-005',
            transactionType: 'NEFT',
            status: 'Approved',
            date: '14 Jul 2026',
          ),
        ],
      );
      onSuccess(mockModel);
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.getWithToken,
        url: ApiConstants.homeFeed,
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        onSuccess(
          HomeModel.fromJson(Map<String, dynamic>.from(response.data as Map)),
        );
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }
}
