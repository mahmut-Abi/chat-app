import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'message.dart';

part 'conversation.g.dart';

@JsonSerializable(explicitToJson: true)
class Conversation extends Equatable {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? systemPrompt;
  final Map<String, dynamic> settings;
  final List<String> tags;
  final String? groupId;
  final int? totalTokens;
  final bool isPinned;
  final bool isTemporary;

  const Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.systemPrompt,
    this.settings = const {},
    this.tags = const [],
    this.groupId,
    this.totalTokens,
    this.isPinned = false,
    this.isTemporary = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  Conversation copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? systemPrompt,
    Map<String, dynamic>? settings,
    List<String>? tags,
    String? groupId,
    int? totalTokens,
    bool? isPinned,
    bool? isTemporary,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      settings: settings ?? this.settings,
      tags: tags ?? this.tags,
      groupId: groupId ?? this.groupId,
      totalTokens: totalTokens ?? this.totalTokens,
      isPinned: isPinned ?? this.isPinned,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    messages,
    createdAt,
    updatedAt,
    systemPrompt,
    settings,
    tags,
    groupId,
    totalTokens,
    isPinned,
    isTemporary,
  ];
}

@JsonSerializable()
class ConversationGroup extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? color;
  final int? sortOrder;

  const ConversationGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    this.color,
    this.sortOrder,
  });

  factory ConversationGroup.fromJson(Map<String, dynamic> json) =>
      _$ConversationGroupFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationGroupToJson(this);

  ConversationGroup copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? color,
    int? sortOrder,
  }) {
    return ConversationGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, color, sortOrder];
}

@JsonSerializable()
class ModelConfig extends Equatable {
  final String model;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;

  const ModelConfig({
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ModelConfigToJson(this);

  ModelConfig copyWith({
    String? model,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
  }) {
    return ModelConfig(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
    );
  }

  @override
  List<Object?> get props => [
    model,
    temperature,
    maxTokens,
    topP,
    frequencyPenalty,
    presencePenalty,
  ];
}
