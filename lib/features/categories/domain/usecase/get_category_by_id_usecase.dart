import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/repositories/category_repository.dart';

class GetCategoryByIdParams {
  GetCategoryByIdParams({required this.id});
  final String id;
}

class GetCategoryByIdUseCase
    implements UseCase<CategoryEntity, GetCategoryByIdParams> {
  const GetCategoryByIdUseCase({required this.repository});
  final CategoryRepository repository;

  @override
  ResultFuture<CategoryEntity> call(GetCategoryByIdParams params) =>
      repository.getCategoryById(params.id);
}
