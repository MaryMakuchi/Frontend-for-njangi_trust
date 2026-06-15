import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device currently has a network connection, as a stream
/// that emits the current state immediately and then on every change.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Stream<bool> get onStatusChange async* {
    // Emit the current status first so listeners don't wait for a change.
    try {
      yield _isOnline(await _connectivity.checkConnectivity());
    } catch (_) {
      yield true; // Assume online if the platform can't tell us.
    }
    yield* _connectivity.onConnectivityChanged.map(_isOnline);
  }

  Future<bool> isOnline() async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (_) {
      return true;
    }
  }
}
