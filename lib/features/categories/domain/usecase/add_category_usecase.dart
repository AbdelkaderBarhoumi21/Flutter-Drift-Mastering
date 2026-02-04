import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/repositories/category_repository.dart';

class AddCategoryParams {
  AddCategoryParams({required this.category});
  final CategoryEntity category;
}

class AddCategoryUseCase implements UseCase<CategoryEntity, AddCategoryParams> {
  const AddCategoryUseCase({required this.repository});
  final CategoryRepository repository;

  @override
  ResultFuture<CategoryEntity> call(AddCategoryParams params) =>
      repository.addCategory(params.category);
}
