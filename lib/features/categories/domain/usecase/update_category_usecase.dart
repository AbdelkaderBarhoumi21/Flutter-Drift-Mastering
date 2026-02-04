import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/repositories/category_repository.dart';

class UpdateCategoryParams {
  UpdateCategoryParams({required this.category});
  final CategoryEntity category;
}

class UpdateCategoryUseCase
    implements UseCase<CategoryEntity, UpdateCategoryParams> {
  const UpdateCategoryUseCase({required this.repository});
  final CategoryRepository repository;

  @override
  ResultFuture<CategoryEntity> call(UpdateCategoryParams params) =>
      repository.updateCategory(params.category);
}
