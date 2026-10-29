import 'api_error_model.dart';

class ApiResult<T> {
  final T? data;
  final ApiErrorModel? error;

  ApiResult.success(this.data) : error = null;
  ApiResult.failure(this.error) : data = null;

  bool get isSuccess => data != null;
  bool get isFailure => error != null;

  void when({
    required Function(T data) success,
    required Function(ApiErrorModel error) failure,
  }) {
    if (isSuccess) {
      success(data!);
    } else if (isFailure) {
      failure(error!);
    }
  }
}
