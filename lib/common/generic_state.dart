import 'package:doc_genie/common/custom_exception.dart';

abstract class GenericState {
  const GenericState();
}

class InitialState extends GenericState {
  const InitialState();
}

class LoadingState extends GenericState {
  const LoadingState();
}

class LoadedState<T> extends GenericState {
  const LoadedState({
    this.response,
    this.isLoadMore = false,
    this.nextPage = '',
  });

  final T? response;
  final bool? isLoadMore;
  final String? nextPage;

  LoadedState<T> copyWith({bool? isLoadMore, T? response, String? nextPage}) {
    return LoadedState<T>(
      response: response ?? this.response,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      nextPage: nextPage ?? this.nextPage,
    );
  }
}

class ErrorState extends GenericState {
  const ErrorState(this.exception);

  final CustomException exception;
}
