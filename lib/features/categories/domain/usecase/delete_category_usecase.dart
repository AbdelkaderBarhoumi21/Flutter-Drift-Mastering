import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/repositories/category_repository.dart';

class DeleteCategoryParams {
  DeleteCategoryParams({required this.id});
  final String id;
}

class DeleteCategoryUseCase implements UseCase<void, DeleteCategoryParams> {
  const DeleteCategoryUseCase({required this.repository});
  final CategoryRepository repository;

  @override
  ResultFuture<void> call(DeleteCategoryParams params) =>
      repository.deleteCategory(params.id);
}
