import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/repository/maker_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Scan state — holds upload + scan progress and the result
class ScanState {
  const ScanState({
    this.isUploading = false,
    this.isScanning = false,
    this.result,
    this.error,
  });

  final bool isUploading;
  final bool isScanning;
  final ScanResultModel? result;
  final String? error;

  ScanState copyWith({
    bool? isUploading,
    bool? isScanning,
    ScanResultModel? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      ScanState(
        isUploading: isUploading ?? this.isUploading,
        isScanning: isScanning ?? this.isScanning,
        result: clearResult ? null : (result ?? this.result),
        error: clearError ? null : (error ?? this.error),
      );
}

final autoScanControllerProvider =
    StateNotifierProvider<ScanController, ScanState>(
      (ref) => ScanController(isAuto: true),
    );

final manualScanControllerProvider =
    StateNotifierProvider<ScanController, ScanState>(
      (ref) => ScanController(isAuto: false),
    );

class ScanController extends StateNotifier<ScanState> {
  ScanController({required this.isAuto}) : super(const ScanState());

  final bool isAuto;
  final MakerRepository _repo = MakerRepository();

  Future<void> scan(PlatformFile file) async {
    state = state.copyWith(isScanning: true, clearResult: true, clearError: true);
    final scan = isAuto ? _repo.autoScan : _repo.manualScan;
    await scan(
      file: file,
      onSuccess: (result) {
        state = state.copyWith(isScanning: false, result: result);
      },
      onfailure: (ex) {
        state = state.copyWith(
          isScanning: false,
          error: ex.message,
          clearResult: true,
        );
      },
    );
  }

  void reset() => state = const ScanState();
}

// Submit state
final autoSubmitControllerProvider =
    StateNotifierProvider<SubmitController, GenericState>(
      (ref) => SubmitController(isAuto: true),
    );

final manualSubmitControllerProvider =
    StateNotifierProvider<SubmitController, GenericState>(
      (ref) => SubmitController(isAuto: false),
    );

class SubmitController extends StateNotifier<GenericState> {
  SubmitController({required this.isAuto}) : super(const InitialState());

  final bool isAuto;
  final MakerRepository _repo = MakerRepository();

  Future<void> submit({
    required String documentId,
    required TransactionType type,
    required Map<String, String> fields,
    required String isEdited,
    required Function(DocumentModel) onSuccess,
  }) async {
    state = const LoadingState();
    await _repo.submitDocument(
      documentId: documentId,
      type: type,
      fields: fields,
      isEdited: isEdited,
      onSuccess: (doc) {
        state = LoadedState<DocumentModel>(response: doc);
        onSuccess(doc);
      },
      onfailure: (ex) => state = ErrorState(ex),
    );
  }

  void reset() => state = const InitialState();
}

// Documents list
final autoDocsControllerProvider =
    StateNotifierProvider<DocsController, GenericState>(
      (ref) => DocsController(isAuto: true),
    );

final manualDocsControllerProvider =
    StateNotifierProvider<DocsController, GenericState>(
      (ref) => DocsController(isAuto: false),
    );

class DocsController extends StateNotifier<GenericState> {
  DocsController({required this.isAuto}) : super(const InitialState()) {
    fetchDocs();
  }

  final bool isAuto;
  final MakerRepository _repo = MakerRepository();

  Future<void> fetchDocs({bool shouldRefresh = false}) async {
    if (!shouldRefresh && state is LoadedState) return;
    state = const LoadingState();
    await _repo.fetchDocuments(
      isAutoScan: isAuto,
      onSuccess: (list) =>
          state = LoadedState<List<DocumentModel>>(response: list),
      onfailure: (ex) => state = ErrorState(ex),
    );
  }

  void prependDoc(DocumentModel doc) {
    final current = state is LoadedState<List<DocumentModel>>
        ? (state as LoadedState<List<DocumentModel>>).response ?? []
        : <DocumentModel>[];
    state = LoadedState<List<DocumentModel>>(response: [doc, ...current]);
  }
}
