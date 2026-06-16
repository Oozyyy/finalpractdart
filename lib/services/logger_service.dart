import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import '../models/action_type.dart';

class LoggerService {
  final String _logPath = "logs.txt";
  late SendPort _sendPort;
  Isolate? _isolate;

  Future<void> init() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_loggingIsolate, [receivePort.sendPort, _logPath]);
    _sendPort = await receivePort.first as SendPort;
  }

  void log(ActionType action, String message) {
    final timestamp = DateTime.now().toString().split('.').first;
    final logLine = "[$timestamp] [${action.name}] $message";
    _sendPort.send(logLine);
  }

  Future<List<String>> getLastLines(int n) async {
    final file = File(_logPath);
    if (!await file.exists()) return ["Лог-файл еще не создан."];

    final lines = await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();

    if (lines.length <= n) return lines;
    return lines.sublist(lines.length - n);
  }

  static void _loggingIsolate(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final String path = args[1];
    final receivePort = ReceivePort();
    
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is String) {
        try {
          final file = File(path);
          file.writeAsStringSync("$message\n", mode: FileMode.append);
        } catch (e) {
          print("\n[!] Ошибка записи лога: $e");
        }
      }
    });
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.beforeNextEvent);
  }
}