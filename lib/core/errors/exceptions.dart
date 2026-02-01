abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

/// Thrown when server returns an error response
// extends = inherit (parent-child relationship)
class ServerException extends AppException {
  const ServerException([super.message = 'Server not occured']);
}

/// Thrown when there's no internet connection
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Thrown when cached data is not found
class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred']);
}

/// Thrown when validation fails
class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation failed']);
}

class SyncConflictException implements AppException {
  const SyncConflictException({
    required this.message,
    required this.localData,
    required this.remoteData,
  });
  @override
  final String message;
  final dynamic localData;
  final dynamic remoteData;
}
