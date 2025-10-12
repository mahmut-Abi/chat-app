import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'model.g.dart';

@JsonSerializable()
class AiModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int? contextLength;
  final bool supportsFunctions;
  final bool supportsVision;
  final Map<String, dynamic>? metadata;

  const AiModel({
    required this.id,
    required this.name,
    this.description,
    this.contextLength,
    this.supportsFunctions = false,
    this.supportsVision = false,
    this.metadata,
  });

  factory AiModel.fromJson(Map<String, dynamic> json) =>
      _$AiModelFromJson(json);

  Map<String, dynamic> toJson() => _$AiModelToJson(this);

  AiModel copyWith({
    String? id,
    String? name,
    String? description,
    int? contextLength,
    bool? supportsFunctions,
    bool? supportsVision,
    Map<String, dynamic>? metadata,
  }) {
    return AiModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contextLength: contextLength ?? this.contextLength,
      supportsFunctions: supportsFunctions ?? this.supportsFunctions,
      supportsVision: supportsVision ?? this.supportsVision,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        contextLength,
        supportsFunctions,
        supportsVision,
        metadata,
      ];
}
