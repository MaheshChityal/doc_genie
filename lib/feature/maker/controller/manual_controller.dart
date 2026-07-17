import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/feature/maker/model/manual_scan_model.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/feature/maker/repository/manual_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Manual upload + scan ─────────────────────────────────────────────────
class ManualScanState {
  const ManualScanState({this.isScanning = false, this.result, this.error});

  final bool isScanning;
  final ManualScanModel? result;
  final String? error;

  ManualScanState copyWith({
    bool? isScanning,
    ManualScanModel? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      ManualScanState(
        isScanning: isScanning ?? this.isScanning,
        result: clearResult ? null : (result ?? this.result),
        error: clearError ? null : (error ?? this.error),
      );
}

final manualScanControllerProvider =
    StateNotifierProvider<ManualScanController, ManualScanState>(
  (ref) => ManualScanController(),
);

class ManualScanController extends StateNotifier<ManualScanState> {
  ManualScanController() : super(const ManualScanState());

  final ManualRepository _repo = ManualRepository();

  Future<void> scan(PlatformFile file) async {
    state =
        state.copyWith(isScanning: true, clearResult: true, clearError: true);
    await _repo.scan(
      file: file,
      onSuccess: (result) =>
          state = state.copyWith(isScanning: false, result: result),
      onfailure: (ex) => state = state.copyWith(
        isScanning: false,
        error: ex.message,
        clearResult: true,
      ),
    );
  }

  void reset() => state = const ManualScanState();
}

// ── Manual submit ────────────────────────────────────────────────────────
final manualSubmitControllerProvider =
    StateNotifierProvider<ManualSubmitController, GenericState>(
  (ref) => ManualSubmitController(),
);

class ManualSubmitController extends StateNotifier<GenericState> {
  ManualSubmitController() : super(const InitialState());

  final ManualRepository _repo = ManualRepository();

  Future<void> submit({
    required TransactionType type,
    required Map<String, String> fields,
    required String isEdited,
    String remark = '',
    String fileName = '',
    required Function(String referenceNumber) onSuccess,
  }) async {
    state = const LoadingState();
    await _repo.submitDocument(
      type: type,
      fields: fields,
      isEdited: isEdited,
      remark: remark,
      fileName: fileName,
      onSuccess: (refNo) {
        state = LoadedState<String>(response: refNo);
        onSuccess(refNo);
      },
      onfailure: (ex) => state = ErrorState(ex),
    );
  }

  void reset() => state = const InitialState();
}
