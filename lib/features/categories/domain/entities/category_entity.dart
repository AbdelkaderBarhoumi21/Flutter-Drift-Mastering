import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  final String id;
  final String name;
  final String icon;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  @override
  List<Object?> get props => [
    id,
    name,
    icon,
    color,
    createdAt,
    updatedAt,
    isDeleted,
  ];
}
