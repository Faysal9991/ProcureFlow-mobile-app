import 'package:equatable/equatable.dart';

sealed class ApiResult<T> extends Equatable {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure({required this.message, this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  List<Object?> get props => [message, code, cause];
}

class PaginatedResult<T> extends Equatable {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;

  @override
  List<Object?> get props => [items, page, pageSize, total];
}
