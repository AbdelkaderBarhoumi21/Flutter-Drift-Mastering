

import 'package:dartz/dartz.dart';
import 'package:flutter_drift_advanced_project/core/errors/exceptions.dart';
import 'package:flutter_drift_advanced_project/core/errors/failures.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/data/datasource/category_local_datasource.dart';
import 'package:flutter_drift_advanced_project/features/categories/data/models/category_model.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {

  const CategoryRepositoryImpl({required this.localDataSource});
  final CategoryLocalDataSource localDataSource;

  @override
  ResultFuture<List<CategoryEntity>> getCategories() async {
    try {
      final models = await localDataSource.getCategories();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<CategoryEntity> getCategoryById(String id) async {
    try {
      final model = await localDataSource.getCategoryById(id);
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<CategoryEntity> addCategory(CategoryEntity category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      final savedModel = await localDataSource.addCategory(model);
      return Right(savedModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<CategoryEntity> updateCategory(CategoryEntity category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      final updatedModel = await localDataSource.updateCategory(model);
      return Right(updatedModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> deleteCategory(String id) async {
    try {
      await localDataSource.deleteCategory(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() => localDataSource.watchCategories().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
}