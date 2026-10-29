import 'package:json_annotation/json_annotation.dart';
part 'api_error_model.g.dart';

@JsonSerializable()
class ApiErrorModel {
  final String? message;
  final int? code;

  /// The raw, unformatted error value as returned by the server (before
  /// underscore-to-space display formatting). Used to detect specific error
  /// kinds (e.g. an active session on another device) without relying on
  /// display wording.
  final String? rawMessage;

  ApiErrorModel({
    required this.message,
    this.code,
    this.rawMessage,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorModelToJson(this);
}
