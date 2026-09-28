/// Base Exception classes for the Data Layer.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException([this.message = 'Server error occurred', this.statusCode]);

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network connection failed']);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException([this.message = 'Authentication failed', this.statusCode]);

  @override
  String toString() => 'AuthException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => 'CacheException: $message';
}
