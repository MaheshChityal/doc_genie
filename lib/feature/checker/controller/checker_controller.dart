import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/feature/checker/model/checker_models.dart';
import 'package:doc_genie/feature/checker/repository/checker_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final checkerControllerProvider =
    StateNotifierProvider<CheckerController, GenericState>(
      (ref) => CheckerController(const InitialState()),
    );

class CheckerController extends StateNotifier<GenericState> {
  CheckerController(super.state) {
    fetchDocuments();
  }

  final CheckerRepository _repo = CheckerRepository();

  Future<void> fetchDocuments({bool shouldRefresh = false}) async {
    if (!shouldRefresh && state is LoadedState) return;
    state = const LoadingState();
    await _repo.fetchDocuments(
      onSuccess: (list) =>
          state = LoadedState<List<CheckerDocModel>>(response: list),
      onfailure: (ex) => state = ErrorState(ex),
    );
  }

  Future<String?> decide(String id, String decision) async {
    final error = await _repo.decide(id, decision);
    if (error != null) return error;
    _updateStatus(id, decision);
    return null;
  }

  void _updateStatus(String id, String decision) {
    if (state is! LoadedState<List<CheckerDocModel>>) return;
    final current =
        (state as LoadedState<List<CheckerDocModel>>).response ?? [];
    final updated = current
        .map((d) => d.id == id ? d.copyWith(status: decision) : d)
        .toList();
    state = LoadedState<List<CheckerDocModel>>(response: updated);
  }
}
