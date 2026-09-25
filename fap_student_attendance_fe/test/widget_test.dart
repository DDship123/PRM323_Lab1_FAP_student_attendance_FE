import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fap_student_attendance_fe/app.dart';

void main() {
  testWidgets('Attendly app smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AttendlyApp());
    await tester.pumpAndSettle();

    // Verify login screen renders with title and button
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('FPT UNIVERSITY'), findsOneWidget);
  });
}
