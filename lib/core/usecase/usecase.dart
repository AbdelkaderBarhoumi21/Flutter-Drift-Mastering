import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';

/// Base class for all use cases
/// [Type] is the return type
/// [Params] is the input parameters type
abstract class UseCase<Type, Params> {
  ResultFuture<Type> call(Params params);
}

/// Used when use case doesn't need parameters
class NoParams {
  const NoParams();
}
