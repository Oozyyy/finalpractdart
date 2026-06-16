import 'dart:io';
import 'dart:typed_data';
import '../models/motorcycle.dart';
import '../exceptions/app_exceptions.dart';

class BinaryStorage {
  final String filePath;

  BinaryStorage(this.filePath);

  Future<void> save(List<Motorcycle> list) async {
    try {
      final file = File(filePath);
      final builder = BytesBuilder();

      final countData = ByteData(4)..setInt32(0, list.length, Endian.big);
      builder.add(countData.buffer.asUint8List());

      for (var item in list) {
        builder.add(item.toBytes());
      }

      await file.writeAsBytes(builder.toBytes());
    } catch (e) {
      throw StorageException("Не удалось сохранить данные в файл: $e");
    }
  }

  Future<List<Motorcycle>> load() async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException("Файл данных не найден");
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return [];

      final reader = TypeReader();
      final count = reader.readInt32(bytes);
      final List<Motorcycle> list = [];

      for (int i = 0; i < count; i++) {
        list.add(Motorcycle.fromBytes(bytes, reader));
      }
      return list;
    } catch (e) {
      throw StorageException("Ошибка чтения бинарного файла: $e");
    }
  }
}