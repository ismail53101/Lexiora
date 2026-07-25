import 'dart:io';

/// Abstraction over "is the device online right now?".
///
/// Kept as an interface so the online-fallback logic depends on a contract, not
/// on `dart:io`, and can be faked in tests.
abstract interface class ConnectivityService {
  /// Returns true when the device appears to have working internet access.
  Future<bool> hasConnection();
}

/// Default [ConnectivityService] backed by a lightweight DNS lookup.
///
/// A successful lookup of a well-known host is a cheap, dependency-free signal
/// that the device is online (it avoids pulling in a platform plugin). Any
/// failure — no DNS, timeout, airplane mode — is treated as "offline".
class NetworkConnectivityService implements ConnectivityService {
  const NetworkConnectivityService({
    this.probeHosts = const <String>['one.one.one.one', 'example.com'],
    this.timeout = const Duration(seconds: 4),
  });

  final List<String> probeHosts;
  final Duration timeout;

  @override
  Future<bool> hasConnection() async {
    for (final String host in probeHosts) {
      try {
        final List<InternetAddress> result =
            await InternetAddress.lookup(host).timeout(timeout);
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } on Object {
        // Try the next host; if all fail we report offline.
      }
    }
    return false;
  }
}
