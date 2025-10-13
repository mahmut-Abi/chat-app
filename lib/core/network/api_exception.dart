class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  ApiException({required this.message, this.statusCode, this.error});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException({String? message})
    : super(message: message ?? 'Network connection failed');
}

class TimeoutException extends ApiException {
  TimeoutException({String? message})
    : super(message: message ?? 'Request timeout');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
    : super(
        message: message ?? 'Invalid API key or unauthorized',
        statusCode: 401,
      );
}

class RateLimitException extends ApiException {
  RateLimitException({String? message})
    : super(message: message ?? 'Rate limit exceeded', statusCode: 429);
}
