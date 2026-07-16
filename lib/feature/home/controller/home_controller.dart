import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/feature/home/model/home_model.dart';
import 'package:doc_genie/feature/home/repository/home_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeControllerProvider =
    StateNotifierProvider<HomeController, GenericState>(
      (ref) => HomeController(const InitialState()),
    );

class HomeController extends StateNotifier<GenericState> {
  HomeController(super.state) {
    fetchHomeFeed();
  }

  final HomeRepository _repo = HomeRepository();

  Future<void> fetchHomeFeed({bool shouldRefresh = false}) async {
    if (!shouldRefresh && state is LoadedState) return;
    state = const LoadingState();
    await _repo.fetchHomeFeed(
      onSuccess: (model) => state = LoadedState<HomeModel>(response: model),
      onfailure: (ex) => state = ErrorState(ex),
    );
  }
}
