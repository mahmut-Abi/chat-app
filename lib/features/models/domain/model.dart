import 'package:freezed_annotation/freezed_annotation.dart';

part 'model.freezed.dart';
part 'model.g.dart';

@freezed
class AiModel with _$AiModel {
  const factory AiModel({
    required String id,
    required String name,
    String? description,
    int? contextLength,
    @Default(false) bool supportsFunctions,
    @Default(false) bool supportsVision,
    Map<String, dynamic>? metadata,
  }) = _AiModel;

  factory AiModel.fromJson(Map<String, dynamic> json) =>
      _$AiModelFromJson(json);
}
