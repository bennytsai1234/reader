import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_location.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';

class ReaderSessionCoordinator {
  final ReaderSessionState _state;
  final ReaderProgressStore _store;
  final Book Function() _book;
  final List<BookChapter> Function() _chapters;
  final Future<void> Function(int chapterIndex, String title, int charOffset)
  _writeProgress;

  ReaderSessionCoordinator({
    required ReaderSessionState state,
    required ReaderProgressStore store,
    required Book Function() book,
    required List<BookChapter> Function() chapters,
    required Future<void> Function(int chapterIndex, String title, int charOffset)
    writeProgress,
  }) : _state = state,
       _store = store,
       _book = book,
       _chapters = chapters,
       _writeProgress = writeProgress;

  ReaderLocation get sessionLocation => _state.sessionLocation;
  ReaderLocation get visibleLocation => _state.visibleLocation;
  ReaderLocation get durableLocation => _state.durableLocation;
  ReaderSessionPhase get phase => _state.phase;

  void updateSessionLocation(ReaderLocation location) {
    _state.updateSessionLocation(location);
  }

  void updateVisibleLocation(ReaderLocation location) {
    _state.updateVisibleLocation(location);
  }

  void updateDurableLocation(ReaderLocation location) {
    _state.updateDurableLocation(location);
  }

  void updatePhase(ReaderSessionPhase phase) {
    _state.updatePhase(phase);
  }

  Future<void> persistLocation(ReaderLocation location) async {
    final normalized = location.normalized();
    updateSessionLocation(normalized);
    updateDurableLocation(normalized);
    await _store.persistCharOffset(
      write: _writeProgress,
      book: _book(),
      chapters: _chapters(),
      chapterIndex: normalized.chapterIndex,
      charOffset: normalized.charOffset,
    );
  }
}
