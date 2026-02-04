// ─────────────────────────────────────────────────────────────────────────────
// lib/core/network/network_exceptions.dart
// ─────────────────────────────────────────────────────────────────────────────

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException(super.message);
}

class ValidationException extends NetworkException {
  final Map<String, dynamic>? errors;
  ValidationException(super.message, this.errors);
}

class NotFoundException extends NetworkException {
  NotFoundException(super.message);
}

class ServerException extends NetworkException {
  ServerException(super.message);
}
