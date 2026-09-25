import 'network_info_io.dart'
    if (dart.library.html) 'network_info_web.dart' as impl;

class NetworkInfo {
  static const int defaultPort = 5000;

  static Future<String> getLocalHost({int port = defaultPort}) {
    return impl.getLocalHostAddress(port: port);
  }
}
