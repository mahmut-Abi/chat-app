import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'model.g.dart';

@JsonSerializable()
class AiModel extends Equatable {
  final String id;
  final String name;
  final String apiConfigId; // 关联的 API 配置 ID
  final String apiConfigName; // API 配置名称，用于显示
  final String? description;
  final int? contextLength;
  final bool supportsFunctions;
  final bool supportsVision;
  final Map<String, dynamic>? metadata;

  const AiModel({
    required this.id,
    required this.name,
    required this.apiConfigId,
    required this.apiConfigName,
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
    String? apiConfigId,
    String? apiConfigName,
    String? description,
    int? contextLength,
    bool? supportsFunctions,
    bool? supportsVision,
    Map<String, dynamic>? metadata,
  }) {
    return AiModel(
      id: id ?? this.id,
      name: name ?? this.name,
      apiConfigId: apiConfigId ?? this.apiConfigId,
      apiConfigName: apiConfigName ?? this.apiConfigName,
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
    apiConfigId,
    apiConfigName,
    description,
    contextLength,
    supportsFunctions,
    supportsVision,
    metadata,
  ];
}
