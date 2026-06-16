import '../models/motorcycle.dart';
import '../repository/repository.dart';
import '../storage/binary_storage.dart';
import 'logger_service.dart';
import '../models/action_type.dart';
import '../exceptions/app_exceptions.dart';

class SalonService {
  final Repository _repository;
  final BinaryStorage _storage;
  final LoggerService _logger;

  SalonService(this._repository, this._storage, this._logger);

  Future<void> loadData() async {
    final items = await _storage.load();
    for (var item in items) {
      _repository.add(item);
    }
  }

  Future<void> addMotorcycle(Motorcycle bike) async {
    _repository.add(bike);
    await _storage.save(_repository.getAll());
    _logger.log(ActionType.ADD, "Добавлен мотоцикл ID=${bike.id} (${bike.brand})");
  }

  Future<void> deleteMotorcycle(int id) async {
    if (_repository.getById(id) == null) {
      throw NotFoundException("Мотоцикл с ID=$id не найден в системе.");
    }
    _repository.remove(id);
    await _storage.save(_repository.getAll());
    _logger.log(ActionType.DELETE, "Удален мотоцикл с ID=$id");
  }

  Future<void> updateMotorcycle(Motorcycle bike) async {
    if (_repository.getById(bike.id) == null) {
      throw NotFoundException("Мотоцикл с ID=${bike.id} не найден для редактирования.");
    }
    _repository.update(bike);
    await _storage.save(_repository.getAll());
    _logger.log(ActionType.EDIT, "Отредактирован мотоцикл ID=${bike.id}");
  }

  List<Motorcycle> getAll(bool sortByEngine) {
    _logger.log(ActionType.LIST, "Запрос списка всех мотоциклов");
    final list = _repository.getAll();
    if (sortByEngine) {
      list.sort((a, b) => a.engineVolume.compareTo(b.engineVolume));
    }
    return list;
  }

  List<Motorcycle> search(String query) {
    _logger.log(ActionType.SEARCH, "Поиск по запросу: '$query'");
    return _repository.getAll().where((b) => 
      b.brand.toLowerCase().contains(query.toLowerCase()) || 
      (b.comment?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  String getStats() {
    _logger.log(ActionType.STATS, "Просмотр общей статистики салона");
    final list = _repository.getAll();
    if (list.isEmpty) return "Салон пуст.";
    
    final total = list.length;
    final available = list.where((b) => b.isAvailable).length;
    final avgCc = list.map((b) => b.engineVolume).reduce((a, b) => a + b) / total;
    
    return "Всего байков: $total (В наличии: $available, Нет: ${total - available}). Ср. объем: ${avgCc.toStringAsFixed(1)} cc.";
  }

  int getNewId() => _repository.maxId + 1;
  int getCount() => _repository.getAll().length;
  int getLastId() => _repository.maxId;
}