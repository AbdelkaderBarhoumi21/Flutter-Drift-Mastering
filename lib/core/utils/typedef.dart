import 'package:dartz/dartz.dart';
import 'package:flutter_drift_advanced_project/core/errors/failures.dart';

// Result type for operations that can fail
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid = ResultFuture<void>;
typedef DataMap = Map<String, dynamic>;
