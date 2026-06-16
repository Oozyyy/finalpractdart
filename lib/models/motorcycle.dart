import 'dart:convert';
import 'dart:typed_data';
import 'motorcycle_type.dart';

abstract class Identifiable {
  int getId();
}

class Motorcycle implements Identifiable {
  final int id;
  final String brand;
  final MotorcycleType type;
  final double engineVolume;
  final bool isAvailable;
  final String? comment;

  Motorcycle({
    required this.id,
    required this.brand,
    required this.type,
    required this.engineVolume,
    required this.isAvailable,
    this.comment,
  });

  @override
  int getId() => id;

  Uint8List toBytes() {
    final builder = BytesBuilder();

    final idData = ByteData(4)..setInt32(0, id, Endian.big);
    builder.add(idData.buffer.asUint8List());

    final brandBytes = utf8.encode(brand);
    final brandLenData = ByteData(4)..setInt32(0, brandBytes.length, Endian.big);
    builder.add(brandLenData.buffer.asUint8List());
    builder.add(brandBytes);

    builder.addByte(type.index);

    final engData = ByteData(8)..setFloat64(0, engineVolume, Endian.big);
    builder.add(engData.buffer.asUint8List());

    builder.addByte(isAvailable ? 1 : 0);

    if (comment == null) {
      builder.addByte(0x00);
    } else {
      builder.addByte(0x01);
      final commentBytes = utf8.encode(comment!);
      final commentLenData = ByteData(4)..setInt32(0, commentBytes.length, Endian.big);
      builder.add(commentLenData.buffer.asUint8List());
      builder.add(commentBytes);
    }

    return builder.toBytes();
  }

  factory Motorcycle.fromBytes(Uint8List bytes, TypeReader reader) {
    final id = reader.readInt32(bytes);
    
    final brandLen = reader.readInt32(bytes);
    final brand = utf8.decode(reader.readBytes(bytes, brandLen));
    
    final typeIndex = reader.readByte(bytes);
    final type = MotorcycleType.values[typeIndex];
    
    final engineVolume = reader.readFloat64(bytes);
    final isAvailable = reader.readByte(bytes) == 1;
    
    final hasComment = reader.readByte(bytes) == 0x01;
    String? comment;
    if (hasComment) {
      final commentLen = reader.readInt32(bytes);
      comment = utf8.decode(reader.readBytes(bytes, commentLen));
    }

    return Motorcycle(
      id: id,
      brand: brand,
      type: type,
      engineVolume: engineVolume,
      isAvailable: isAvailable,
      comment: comment,
    );
  }
}

class TypeReader {
  int offset = 0;

  int readByte(Uint8List bytes) {
    int value = bytes[offset];
    offset += 1;
    return value;
  }

  int readInt32(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes, offset, offset + 4);
    offset += 4;
    return byteData.getInt32(0, Endian.big);
  }

  double readFloat64(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes, offset, offset + 8);
    offset += 8;
    return byteData.getFloat64(0, Endian.big);
  }

  Uint8List readBytes(Uint8List bytes, int length) {
    final result = bytes.sublist(offset, offset + length);
    offset += length;
    return result;
  }
}