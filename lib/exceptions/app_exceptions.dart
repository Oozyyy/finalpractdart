class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => "Ошибка валидации: $message";
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => "Не найдено: $message";
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => "Ошибка хранилища: $message";
}