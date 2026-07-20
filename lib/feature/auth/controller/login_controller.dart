import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/feature/auth/model/login_model.dart';
import 'package:doc_genie/feature/auth/repository/auth_repository.dart';
import 'package:doc_genie/services/secure_helper.dart';
import 'package:doc_genie/services/session_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, GenericState>(
      (ref) => LoginController(const InitialState()),
    );

class LoginController extends StateNotifier<GenericState> {
  LoginController(super.state);

  final AuthRepository _repo = AuthRepository();

  Future<void> login({
    required String employeeCode,
    required String password,
  }) async {
    state = const LoadingState();
    await _repo.login(
      employeeCode: employeeCode,
      password: password,
      onSuccess: (LoginModel model) async {
        await SecureHelper.instance.saveTokens(
          accessToken: model.accessToken,
          refreshToken: model.refreshToken,
        );
        await SecureHelper.instance.saveRole(model.role);
        if (model.user != null) {
          await SecureHelper.instance.saveUser(model.user!.encode());
        }
        AppClient.token = model.accessToken;
        AppClient.refresh = model.refreshToken;
        SessionManager.instance.start();
        state = LoadedState<LoginModel>(response: model);
      },
      onfailure: (exception) {
        state = ErrorState(exception);
      },
    );
  }

  void reset() => state = const InitialState();
}
