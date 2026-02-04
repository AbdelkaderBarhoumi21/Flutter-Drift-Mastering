import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  // Local operations
  ResultFuture<List<CategoryEntity>> getCategories();
  ResultFuture<CategoryEntity> getCategoryById(String id);
  ResultFuture<CategoryEntity> addCategory(CategoryEntity category);
  ResultFuture<CategoryEntity> updateCategory(CategoryEntity category);
  ResultFuture<void> deleteCategory(String id);

  // Stream operations
  Stream<List<CategoryEntity>> watchCategories();
}
