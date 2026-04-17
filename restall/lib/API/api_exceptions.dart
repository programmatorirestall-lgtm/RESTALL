/// Eccezione base per errori specifici dell'API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    if (statusCode != null) {
      return "ApiException: $message (Status Code: $statusCode)";
    }
    return "ApiException: $message";
  }
}

/// Lanciata quando il token di autenticazione è mancante, invalido o scaduto (HTTP 401).
class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

/// Lanciata per errori di validazione o richieste malformate (HTTP 400).
class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message, 400);
}

/// Lanciata quando la risorsa richiesta non viene trovata (HTTP 404).
class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

/// Lanciata per errori generici del server (HTTP 5xx).
class ServerException extends ApiException {
  ServerException(String message) : super(message, 500);
}

/// Lanciata quando si riceve una risposta inaspettata o malformata dal server.
class BadResponseException extends ApiException {
  BadResponseException(String message) : super(message);
}
