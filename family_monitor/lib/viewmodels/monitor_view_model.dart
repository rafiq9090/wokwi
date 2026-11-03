import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/monitor_state.dart';
import '../services/device_repository.dart';

class MonitorViewModel extends ChangeNotifier {
  MonitorViewModel({MonitorState? initialState, this._repository})
      : _state = initialState ?? MonitorState.initial();

  MonitorState _state;
  final DeviceRepository? _repository;
  Timer? _pollTimer;

  MonitorState get state => _state;

  bool get isConnected => _repository != null;

  void startPolling() {
    if (_repository == null || _pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
    refresh();
  }

  Future<void> refresh() async {
    if (_repository == null) return;
    try {
      _state = await _repository.fetchState();
    } catch (_) {
      _state = _state.copyWith(deviceOnline: false);
    }
    notifyListeners();
  }

  void simulateFall() {
    _state = _state.copyWith(
      status: MonitorStatus.alarm,
      impactG: 3.4,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  void acknowledgeAlert() {
    _state = _state.copyWith(
      status: MonitorStatus.normal,
      impactG: 1.0,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  String timeAgo() {
    final seconds = DateTime.now().difference(_state.lastUpdated).inSeconds;
    if (seconds < 60) return '${seconds.clamp(1, 59)}s ago';
    return '${(seconds / 60).floor()}m ago';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
