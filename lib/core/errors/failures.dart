import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

// Server/API errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Network connectivity errors
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

// Local database errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Sync conflicts
class SyncConflictFailure extends Failure {
  const SyncConflictFailure({
    required String message,
    required this.localData,
    required this.remoteData,
  }) : super(message);
  final dynamic localData;
  final dynamic remoteData;

  @override
  List<Object> get props => [message, localData, remoteData];
}

// Validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
