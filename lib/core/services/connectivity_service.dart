import 'package:http/http.dart' as http;

/// Abstraction over "is the device online right now?".
///
/// Kept as an interface so the online-fallback logic depends on a contract and
/// can be faked in tests.
abstract interface class ConnectivityService {
  /// Returns true when the device appears to have working internet access.
  Future<bool> hasConnection();
}

/// Default [ConnectivityService] backed by lightweight HTTP probes.
///
/// Any response from a well-known host is treated as online; failures are
/// treated as offline. This works in browsers as well as on Android.
class NetworkConnectivityService implements ConnectivityService {
  const NetworkConnectivityService({
    this.probeHosts = const <String>[
      'https://one.one.one.one',
      'https://example.com',
    ],
    this.timeout = const Duration(seconds: 4),
  });

  final List<String> probeHosts;
  final Duration timeout;

  @override
  Future<bool> hasConnection() async {
    final http.Client client = http.Client();
    try {
      for (final String host in probeHosts) {
        try {
          final http.Response response =
              await client.head(Uri.parse(host)).timeout(timeout);
          if (response.statusCode > 0) return true;
        } on Object {
          // Try the next host; if all fail we report offline.
        }
      }
      return false;
    } finally {
      client.close();
    }
  }
}
