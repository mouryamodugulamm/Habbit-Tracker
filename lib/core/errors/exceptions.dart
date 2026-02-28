/// Base exception for app-level errors. Use for data layer failures.
abstract class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Thrown when a local storage operation fails (e.g. Hive).
class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}
