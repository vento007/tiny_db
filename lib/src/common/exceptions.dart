class TinyDbException implements Exception {
  final String message;

  TinyDbException(this.message);

  @override
  String toString() => 'TinyDbException: $message';
}

class StorageException extends TinyDbException {
  StorageException(super.message);

  @override
  String toString() => 'StorageException: $message';
}

class CorruptStorageException extends StorageException {
  CorruptStorageException(super.message);

  @override
  String toString() => 'CorruptStorageException: $message';
}

class DocumentException extends TinyDbException {
  DocumentException(super.message);

  @override
  String toString() => 'DocumentException: $message';
}

class QueryException extends TinyDbException {
  QueryException(super.message);

  @override
  String toString() => 'QueryException: $message';
}
