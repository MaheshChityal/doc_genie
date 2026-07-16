import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/custom_exception.dart';
import 'package:doc_genie/constants/api_constants.dart';
import 'package:doc_genie/constants/enum_const.dart';
import 'package:doc_genie/feature/auth/model/login_model.dart';

class AuthRepository {
  final AppClient _client = AppClient.instance;

  static const bool useMockAuth = true;

  Future<void> login({
    required String employeeCode,
    required String password,
    required Function(LoginModel) onSuccess,
    required Function(CustomException) onfailure,
  }) async {
    if (useMockAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final role = employeeCode.toUpperCase().startsWith('C')
          ? 'checker'
          : 'maker';
      final Map<String, dynamic> mockResponse = {
        'accessToken': 'mock-access-token',
        'refreshToken': 'mock-refresh-token',
        'role': role,
        'user': {
          'id': '1',
          'name': employeeCode,
          'email': '',
          'employeeCode': employeeCode,
        },
      };
      onSuccess(LoginModel.fromJson(mockResponse));
      return;
    }

    try {
      final response = await _client.request(
        requestType: RequestType.post,
        url: ApiConstants.login,
        parameter: {'employeeCode': employeeCode, 'password': password},
      );

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data != null) {
        onSuccess(
          LoginModel.fromJson(Map<String, dynamic>.from(response.data as Map)),
        );
      } else {
        onfailure(getCustomException(response.data));
      }
    } catch (ex) {
      onfailure(getCustomException(ex));
    }
  }
}
