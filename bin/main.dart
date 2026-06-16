import 'dart:io';
import '../lib/storage/binary_storage.dart';
import '../lib/repository/repository.dart';
import '../lib/services/logger_service.dart';
import '../lib/services/service.dart';
import '../lib/ui/menu.dart';
import '../lib/models/action_type.dart';
import '../lib/models/motorcycle.dart';
import '../lib/models/motorcycle_type.dart';

void main() async {
  final logger = LoggerService();
  await logger.init();

  logger.log(ActionType.START, "Приложение запущено");

  final storage = BinaryStorage("data.bin");
  final repo = Repository();
  final service = SalonService(repo, storage, logger);

  try {
    await service.loadData();
  } on FileSystemException {
    logger.log(ActionType.START, "Файл data.bin не найден, создан новый");
    
    final testBikes = [
      Motorcycle(id: 1, brand: "Yamaha MT-07", type: MotorcycleType.naked, engineVolume: 689.0, isAvailable: true, comment: "Отличное состояние, выхлоп Akrapovic"),
      Motorcycle(id: 2, brand: "Honda CRF1100 Africa Twin", type: MotorcycleType.adventure, engineVolume: 1084.0, isAvailable: true, comment: "Для дальних путешествий"),
      Motorcycle(id: 3, brand: "Kawasaki Ninja ZX-10R", type: MotorcycleType.sport, engineVolume: 998.0, isAvailable: false, comment: "В залоге"),
      Motorcycle(id: 4, brand: "Harley-Davidson Fat Boy", type: MotorcycleType.cruiser, engineVolume: 1868.0, isAvailable: true),
      Motorcycle(id: 5, brand: "Suzuki SV650", type: MotorcycleType.naked, engineVolume: 645.0, isAvailable: true, comment: "Для новичков"),
    ];

    for (var b in testBikes) {
      repo.add(b);
    }
    
    await storage.save(repo.getAll());
  } catch (e) {
    print("[Критическая ошибка хранилища]: $e");
  }

  final menu = Menu(service, logger);
  await menu.run();

  logger.dispose();
}