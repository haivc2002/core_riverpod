/// A sealed class representing the outcome of an asynchronous operation.
///
/// This class provides a structured way to handle results, ensuring that both
/// [Success] and [Failure] states are exhaustively checked at compile-time.
sealed class Result<S> {
  const Result();

  /// Indicates that there is no active network connection.
  static const int isNotConnect = -111;

  /// Indicates that the request exceeded the allowed time limit.
  static const int isTimeOut = -222;

  /// Indicates that the server encountered an internal error (5xx status codes).
  static const int isDueServer = -333;

  /// Represents HTTP-related errors (e.g., 400, 401, 404 status codes).
  static const int isHttp = -444;

  /// Represents a general or unexpected error occurred during execution.
  static const int isError = -555;
}

/// Represents a successful operation, containing the returned data of type [S].
final class Success<S> extends Result<S> {
  const Success(this.value);

  /// The successful result data returned from the operation.
  final S value;
}

/// Represents a failed operation.
///
/// This class encapsulates error information, including a specific [code]
/// and an optional [message] that describes the nature of the failure.
/// It is designed to handle API-specific errors, network issues, and client-side exceptions.
final class Failure<S> extends Result<S> {
  /// Creates a [Failure] instance.
  ///
  /// [code] - The error identifier (see [Result] constants).
  /// [message] - An optional human-readable description of the error.
  const Failure(this.code, [this.message = ""]);

  /// The error code identifying the type of failure.
  final int code;

  /// A descriptive message explaining why the operation failed.
  final String message;
}

/// An exception thrown to immediately halt execution when the session expires
/// (e.g., refresh token fails or 401 persists).
class SessionExpiredException implements Exception {}