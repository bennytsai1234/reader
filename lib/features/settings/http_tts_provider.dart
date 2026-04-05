import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/database/dao/http_tts_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/http_tts.dart';

class HttpTtsProvider extends ChangeNotifier {
  final HttpTtsDao _dao = getIt<HttpTtsDao>();

  List<HttpTTS> _engines = [];
  List<HttpTTS> get engines => _engines;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  HttpTtsProvider() {
    loadEngines();
  }

  Future<void> loadEngines() async {
    _isLoading = true;
    notifyListeners();
    try {
      _engines = await _dao.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upsert(HttpTTS engine) async {
    await _dao.upsert(engine);
    await loadEngines();
  }

  Future<void> delete(int id) async {
    await _dao.deleteById(id);
    await loadEngines();
  }

  Future<void> importAll(List<HttpTTS> engines) async {
    for (final e in engines) {
      await _dao.upsert(e);
    }
    await loadEngines();
  }
}
