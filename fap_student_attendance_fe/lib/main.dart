import 'package:flutter/material.dart';
import 'app.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bỏ qua assertion "Could not find a set of Noto fonts" trên Web
  // (không ảnh hưởng hiển thị, chỉ là warning khi font không cover hết ký tự)
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('Noto') && msg.contains('font')) return; // ignore
    FlutterError.presentError(details);
  };

  await AuthController().init();
  runApp(const AttendlyApp());
}
