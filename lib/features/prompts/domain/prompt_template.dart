import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'prompt_template.g.dart';

@JsonSerializable()
class PromptTemplate extends Equatable {
  final String id;
  final String name;
  final String content;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;

  const PromptTemplate({
    required this.id,
    required this.name,
    required this.content,
    this.category = '通用',
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
  });

  factory PromptTemplate.fromJson(Map<String, dynamic> json) =>
      _$PromptTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$PromptTemplateToJson(this);

  PromptTemplate copyWith({
    String? id,
    String? name,
    String? content,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return PromptTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        content,
        category,
        tags,
        createdAt,
        updatedAt,
        isFavorite,
      ];
}
