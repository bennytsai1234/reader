import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

enum ReaderSessionPhase {
  bootstrapping,
  contentLoading,
  ready,
  repaginating,
  disposed,
}

class ReaderSessionState {
  ReaderLocation _sessionLocation;
  ReaderLocation _visibleLocation;
  ReaderLocation _durableLocation;
  ReaderSessionPhase _phase;

  ReaderSessionState({
    required ReaderLocation initialLocation,
  })  : _sessionLocation = initialLocation.normalized(),
        _visibleLocation = initialLocation.normalized(),
        _durableLocation = initialLocation.normalized(),
        _phase = ReaderSessionPhase.bootstrapping;

  ReaderLocation get sessionLocation => _sessionLocation;
  ReaderLocation get visibleLocation => _visibleLocation;
  ReaderLocation get durableLocation => _durableLocation;
  ReaderSessionPhase get phase => _phase;

  void updateSessionLocation(ReaderLocation location) {
    _sessionLocation = location.normalized();
  }

  void updateVisibleLocation(ReaderLocation location) {
    _visibleLocation = location.normalized();
  }

  void updateDurableLocation(ReaderLocation location) {
    _durableLocation = location.normalized();
  }

  void updatePhase(ReaderSessionPhase phase) {
    _phase = phase;
  }
}
