import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/feature/report/model/report_model.dart';
import 'package:doc_genie/feature/report/repository/report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportControllerProvider =
    StateNotifierProvider<ReportController, GenericState>(
  (ref) => ReportController(const InitialState()),
);

class ReportController extends StateNotifier<GenericState> {
  ReportController(super.state) {
    fetchReport();
  }

  final ReportRepository _repo = ReportRepository();

  Future<void> fetchReport({bool shouldRefresh = false}) async {
    if (!shouldRefresh && state is LoadedState) return;
    state = const LoadingState();
    await _repo.fetchReport(
      onSuccess: (model) => state = LoadedState<ReportModel>(response: model),
      onFailure: (ex) => state = ErrorState(ex),
    );
  }
}
