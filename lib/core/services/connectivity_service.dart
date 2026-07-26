import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device has a usable network interface.
///
/// This answers "is there a route out", not "is the internet reachable" — a
/// captive portal still reads as online. It is used to explain failures, never
/// to gate a request, so an optimistic answer is the right trade-off.
class ConnectivityService {
  const ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  /// Online state, starting with the value at subscription time.
  ///
  /// Emitting the current value first matters: a listener that subscribes while
  /// already offline would otherwise see nothing at all until connectivity
  /// changed. Written as `async*` over the platform stream so there is no
  /// controller to leak — the subscription is owned by whoever listens.
  Stream<bool> get isOnlineStream async* {
    // A failed probe must not make the app claim the user is offline.
    yield await isOnline().catchError((Object _) => true);
    yield* _connectivity.onConnectivityChanged.map(_isOnline);
  }

  Future<bool> isOnline() async {
    return _isOnline(await _connectivity.checkConnectivity());
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
