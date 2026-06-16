import 'dart:io';
import 'dart:isolate';
import '../services/service.dart';
import '../services/logger_service.dart';
import '../models/motorcycle.dart';
import '../models/motorcycle_type.dart';
import '../models/action_type.dart';
import '../exceptions/app_exceptions.dart';

class Menu {
  final SalonService _service;
  final LoggerService _logger;

  Menu(this._service, this._logger);

  Future<void> run() async {
    while (true) {
      _printMenu();
      stdout.write("Выберите действие: ");
      final input = stdin.readLineSync() ?? "";

      try {
        switch (input) {
          case '1': await _addBike(); break;
          case '2': await _deleteBike(); break;
          case '3': await _editBike(); break;
          case '4': _searchBikes(); break;
          case '5': _showAll(); break;
          case '6': _showStats(); break;
          case '7': await _showLogs(); break;
          case '8': await _generateAsynchronousReport(); break;
          case '0':
            _logger.log(ActionType.EXIT, "Выход из приложения");
            print("До свидания!");
            return;
          default:
            print("Неверный пункт меню. Попробуйте снова.");
        }
      } on ValidationException catch (e) {
        print("\n[!] Ошибка ввода: $e. Попробуйте заново.");
        _logger.log(ActionType.ERROR, "ValidationException: ${e.message}");
      } on NotFoundException catch (e) {
        print("\n[!] Элемент не найден: $e");
        _logger.log(ActionType.ERROR, "NotFoundException: ${e.message}");
      } catch (e) {
        print("\n[!] Непредвиденная ошибка: $e");
        _logger.log(ActionType.ERROR, "Unknown Error: $e");
      }
      print("\nНажмите Enter для продолжения...");
      stdin.readLineSync();
    }
  }

  void _printMenu() {
    print("\n=== МОТОСАЛОН ===");
    print("1. Добавить мотоцикл");
    print("2. Удалить мотоцикл (по ID)");
    print("3. Редактировать мотоцикл");
    print("4. Поиск мотоциклов");
    print("5. Показать все (с сортировкой)");
    print("6. Статистика");
    print("7. Показать логи");
    print("8. Асинхронный отчёт (изолят)");
    print("0. Выход");
    print("-----------------");
    print("[Статус] Всего байков в базе: ${_service.getCount()} | Последний ID: ${_service.getLastId()}");
  }

  Future<void> _addBike() async {
    print("\n--- Добавление мотоцикла ---");
    final brand = _readString("Введите марку/модель: ");
    final type = _readType();
    final volume = _readDouble("Введите объем двигателя (куб.см): ");
    final available = _readBool("В наличии? (y/n): ");
    
    stdout.write("Введите комментарий (или оставьте пустым): ");
    String? comment = stdin.readLineSync();
    if (comment != null && comment.trim().isEmpty) comment = null;

    final bike = Motorcycle(
      id: _service.getNewId(),
      brand: brand,
      type: type,
      engineVolume: volume,
      isAvailable: available,
      comment: comment,
    );

    await _service.addMotorcycle(bike);
    print("Мотоцикл успешно добавлен с ID=${bike.id}!");
  }

  Future<void> _deleteBike() async {
    print("\n--- Удаление мотоцикла ---");
    final id = _readInt("Введите ID мотоцикла для удаления: ");
    await _service.deleteMotorcycle(id);
    print("Мотоцикл с ID=$id успешно удален.");
  }

  Future<void> _editBike() async {
    print("\n--- Редактирование мотоцикла ---");
    final id = _readInt("Введите ID мотоцикла для редактирования: ");
    
    final list = _service.getAll(false);
    if (!list.any((b) => b.id == id)) throw NotFoundException("ID $id отсутствует.");

    final brand = _readString("Введите новую марку/модель: ");
    final type = _readType();
    final volume = _readDouble("Введите новый объем двигателя: ");
    final available = _readBool("В наличии? (y/n): ");
    
    stdout.write("Новый комментарий (или пусто): ");
    String? comment = stdin.readLineSync();
    if (comment != null && comment.trim().isEmpty) comment = null;

    final bike = Motorcycle(
      id: id,
      brand: brand,
      type: type,
      engineVolume: volume,
      isAvailable: available,
      comment: comment,
    );

    await _service.updateMotorcycle(bike);
    print("Данные мотоцикла обновлены.");
  }

  void _searchBikes() {
    print("\n--- Поиск мотоциклов ---");
    stdout.write("Введите текст для поиска (марка или коммент): ");
    final q = stdin.readLineSync() ?? "";
    final res = _service.search(q);
    _printList(res);
  }

  void _showAll() {
    print("\n--- Список техники ---");
    stdout.write("Сортировать по кубатуре? (y/n): ");
    final sort = (stdin.readLineSync() ?? "").toLowerCase() == 'y';
    final res = _service.getAll(sort);
    _printList(res);
  }

  void _showStats() {
    print("\n--- Статистика салона ---");
    print(_service.getStats());
  }

  Future<void> _showLogs() async {
    print("\n--- Последние 10 строк лог-файла ---");
    _logger.log(ActionType.VIEW_LOGS, "Пользователь запросил просмотр логов");
    final lines = await _logger.getLastLines(10);
    for (var l in lines) {
      print(l);
    }
  }

  Future<void> _generateAsynchronousReport() async {
    print("\n[Процесс] Запуск генерации отчёта в фоновом изоляте...");
    _logger.log(ActionType.REPORT, "Запуск тяжелого аналитического отчета");

    final receivePort = ReceivePort();
    final list = _service.getAll(false);

    await Isolate.spawn(_reportWorker, [receivePort.sendPort, list]);

    print("Отчёт генерируется в фоне...");
    int counter = 0;
    
    final resultFuture = receivePort.first;
    while (counter < 3) {
      await Future.delayed(const Duration(milliseconds: 400));
      stdout.write(" 🏍️ .");
      counter++;
    }
    print("");

    final String reportResult = await resultFuture as String;
    print("\n=== РЕЗУЛЬТАТЫ ФОНОВОГО ОТЧЕТА ===");
    print(reportResult);
    print("==================================");
  }

  static void _reportWorker(List<dynamic> args) {
    final SendPort replyPort = args[0];
    final List<Motorcycle> data = args[1];

    int heavySum = 0;
    for (int i = 0; i < 5000000; i++) {
      heavySum += i % 2;
    }

    if (data.isEmpty) {
      replyPort.send("Данные отсутствуют. Нечего анализировать.");
      return;
    }

    final Map<MotorcycleType, int> typeCounts = {};
    for (var b in data) {
      typeCounts[b.type] = (typeCounts[b.type] ?? 0) + 1;
    }

    final buffer = StringBuffer();
    buffer.writeln("Анализ распределения категорий мотоциклов:");
    typeCounts.forEach((type, count) {
      buffer.writeln(" - Категория ${type.name.toUpperCase()}: $count шт.");
    });
    buffer.write("Фоновые хэш-вычисления завершены успешно ($heavySum).");

    replyPort.send(buffer.toString());
  }

  String _readString(String prompt) {
    stdout.write(prompt);
    final str = stdin.readLineSync() ?? "";
    if (str.trim().isEmpty) throw ValidationException("Поле не может быть пустым");
    return str;
  }

  int _readInt(String prompt) {
    stdout.write(prompt);
    final str = stdin.readLineSync() ?? "";
    final val = int.tryParse(str);
    if (val == null) throw ValidationException("Нужно ввести корректное число");
    return val;
  }

  double _readDouble(String prompt) {
    stdout.write(prompt);
    final str = stdin.readLineSync() ?? "";
    final val = double.tryParse(str);
    if (val == null || val <= 0) throw ValidationException("Некорректный формат дробного числа");
    return val;
  }

  bool _readBool(String prompt) {
    stdout.write(prompt);
    final str = (stdin.readLineSync() ?? "").toLowerCase();
    return str == 'y' || str == 'yes';
  }

  MotorcycleType _readType() {
    print("Выберите тип мотоцикла:");
    for (var i = 0; i < MotorcycleType.values.length; i++) {
      print("  $i - ${MotorcycleType.values[i].name}");
    }
    final idx = _readInt("Ваш выбор: ");
    if (idx < 0 || idx >= MotorcycleType.values.length) {
      throw ValidationException("Выбран несуществующий индекс типа");
    }
    return MotorcycleType.values[idx];
  }

  void _printList(List<Motorcycle> list) {
    if (list.isEmpty) {
      print("Список пуст.");
      return;
    }
    for (var b in list) {
      print("[ID: ${b.id}] ${b.brand} | Тип: ${b.type.name.toUpperCase()} | Объем: ${b.engineVolume} cc | Доступен: ${b.isAvailable ? 'Да' : 'Нет'} ${b.comment != null ? '(Коммент: ${b.comment})' : ''}");
    }
  }
}