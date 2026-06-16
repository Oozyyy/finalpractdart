import '../models/motorcycle.dart';

class Repository {
  final Map<int, Motorcycle> _items = {};

  void add(Motorcycle item) {
    _items[item.id] = item;
  }

  void remove(int id) {
    _items.remove(id);
  }

  void update(Motorcycle item) {
    _items[item.id] = item;
  }

  Motorcycle? getById(int id) {
    return _items[id];
  }

  List<Motorcycle> getAll() {
    return _items.values.toList();
  }

  int get maxId {
    if (_items.isEmpty) return 0;
    return _items.keys.reduce((a, b) => a > b ? a : b);
  }
}