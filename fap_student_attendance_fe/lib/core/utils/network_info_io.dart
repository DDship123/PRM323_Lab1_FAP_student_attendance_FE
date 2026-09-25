import 'dart:io';

Future<String> getLocalHostAddress({int port = 5000}) async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback && addr.address.isNotEmpty) {
          return '${addr.address}:$port';
        }
      }
    }
  } catch (_) {}
  return '192.168.1.101:$port';
}
