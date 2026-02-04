import 'package:drift/drift.dart';
import 'package:flutter_drift_advanced_project/core/database/app_database.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/entities/category_entity.dart';

class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  // From Drift table to Model
  factory CategoryModel.fromTable(CategoryTable table) => CategoryModel(
    id: table.id,
    name: table.name,
    icon: table.icon,
    color: table.color,
    createdAt: table.createdAt,
    updatedAt: table.updatedAt,
    isDeleted: table.isDeleted,
  );

  // From JSON (API response) to Model
  factory CategoryModel.fromJson(DataMap json) => CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    isDeleted: json['is_deleted'] as bool? ?? false,
  );

  // From Domain Entity to Model
  factory CategoryModel.fromEntity(CategoryEntity entity) => CategoryModel(
    id: entity.id,
    name: entity.name,
    icon: entity.icon,
    color: entity.color,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    isDeleted: entity.isDeleted,
  );

  // To JSON (for API request)
  DataMap toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_deleted': isDeleted,
  };

  // To Domain Entity
  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    name: name,
    icon: icon,
    color: color,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );

  // To Drift Companion (for insert/update)
  CategoriesCompanion toCompanion() => CategoriesCompanion.insert(
    id: id,
    name: name,
    icon: icon,
    color: color,
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    isDeleted: Value(isDeleted),
  );

  final String id;
  final String name;
  final String icon;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
}
