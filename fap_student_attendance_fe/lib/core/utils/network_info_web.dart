Future<String> getLocalHostAddress({int port = 5000}) async {
  final baseUri = Uri.base;
  if (baseUri.host.isNotEmpty && baseUri.host != 'localhost' && baseUri.host != '127.0.0.1') {
    return baseUri.hasPort ? '${baseUri.host}:${baseUri.port}' : baseUri.host;
  }
  return '192.168.1.101:$port';
}
