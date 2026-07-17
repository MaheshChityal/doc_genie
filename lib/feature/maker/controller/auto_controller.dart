import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/feature/maker/model/auto_doc_model.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/repository/auto_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Auto documents list ──────────────────────────────────────────────────
final autoDocsControllerProvider =
    StateNotifierProvider<AutoDocsController, GenericState>(
  (ref) => AutoDocsController(),
);

class AutoDocsController extends StateNotifier<GenericState> {
  AutoDocsController() : super(const InitialState()) {
    fetchDocs();
  }

  final AutoRepository _repo = AutoRepository();

  Future<void> fetchDocs({bool shouldRefresh = false}) async {
    if (!shouldRefresh && state is LoadedState) return;
    state = const LoadingState();
    await _repo.fetchDocuments(
      onSuccess: (list) =>
          state = LoadedState<List<AutoDocModel>>(response: list),
      onfailure: (ex) => state = ErrorState(ex),
    );
  }

  void removeDoc(String id) {
    if (state is! LoadedState<List<AutoDocModel>>) return;
    final current = (state as LoadedState<List<AutoDocModel>>).response ?? [];
    state = LoadedState<List<AutoDocModel>>(
      response: current.where((d) => d.id != id).toList(),
    );
  }
}

// ── Auto submit (from the detail dialog) ─────────────────────────────────
final autoSubmitControllerProvider =
    StateNotifierProvider<AutoSubmitController, GenericState>(
  (ref) => AutoSubmitController(),
);

class AutoSubmitController extends StateNotifier<GenericState> {
  AutoSubmitController() : super(const InitialState());

  final AutoRepository _repo = AutoRepository();

  Future<void> submit({
    required String documentId,
    required TransactionType type,
    required Map<String, String> fields,
    required String isEdited,
    String remark = '',
    required Function(AutoDocModel) onSuccess,
  }) async {
    state = const LoadingState();
    await _repo.submitAutoScanDocument(
      documentId: documentId,
      type: type,
      fields: fields,
      remark: remark,
      onSuccess: (doc) {
        state = LoadedState<AutoDocModel>(response: doc);
        onSuccess(doc);
      },
      onfailure: (ex) => state = ErrorState(ex),
    );
  }

  void reset() => state = const InitialState();
}
