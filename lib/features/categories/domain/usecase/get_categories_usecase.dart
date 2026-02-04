import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_drift_advanced_project/features/categories/domain/repositories/category_repository.dart';

class GetCategoriesUseCase implements UseCase<List<CategoryEntity>, NoParams> {
  const GetCategoriesUseCase({required this.repository});
  final CategoryRepository repository;
  @override
  ResultFuture<List<CategoryEntity>> call(NoParams params) =>
      repository.getCategories();

  Stream<List<CategoryEntity>> watch() => repository.watchCategories();
}
