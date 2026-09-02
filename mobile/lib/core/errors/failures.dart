abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage error occurred.']);
}
