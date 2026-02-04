

import 'package:drift/drift.dart';
import 'package:flutter_drift_advanced_project/core/database/app_database.dart';
import 'package:flutter_drift_advanced_project/core/errors/exceptions.dart';
import 'package:flutter_drift_advanced_project/features/categories/data/models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<CategoryModel> addCategory(CategoryModel category);
  Future<CategoryModel> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Stream<List<CategoryModel>> watchCategories();
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {

  const CategoryLocalDataSourceImpl(this.database);
  final AppDatabase database;

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final results = await (database.select(database.categories)
            ..where((c) => c.isDeleted.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();

      return results.map((c) => CategoryModel.fromTable(c)).toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final result = await (database.select(database.categories)
            ..where((c) => c.id.equals(id)))
          .getSingleOrNull();

      if (result == null) {
        throw const CacheException('Category not found');
      }

      return CategoryModel.fromTable(result);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<CategoryModel> addCategory(CategoryModel category) async {
    try {
      await database.into(database.categories).insert(
            category.toCompanion(),
          );

      return category;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      await (database.update(database.categories)
            ..where((c) => c.id.equals(category.id)))
          .write(category.toCompanion());

      return category;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      // Soft delete
      await (database.update(database.categories)
            ..where((c) => c.id.equals(id)))
          .write(const CategoriesCompanion(
        isDeleted: Value(true),
      ));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Stream<List<CategoryModel>> watchCategories() {
    try {
      return (database.select(database.categories)
            ..where((c) => c.isDeleted.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch()
          .map((results) => results.map((c) => CategoryModel.fromTable(c)).toList());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}