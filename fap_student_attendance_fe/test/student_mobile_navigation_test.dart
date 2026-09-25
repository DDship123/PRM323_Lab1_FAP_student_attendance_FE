import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fap_student_attendance_fe/shared/layouts/desktop_scaffold.dart';

void main() {
  group('Student Mobile Navigation Tests', () {
    testWidgets('DesktopScaffold renders student bottomNavigationBar on mobile screen', (tester) async {
      // Set mobile phone screen size (390 x 844 - iPhone 12/13/14 size)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopScaffold(
            selectedIndex: 0,
            role: UserRole.student,
            body: const Center(child: Text('Student Dashboard Content')),
          ),
        ),
      );

      // Verify bottom navigation bar exists on mobile
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify 4 student destinations exist in bottom nav
      expect(find.text('Buổi học'), findsOneWidget);
      expect(find.text('Tìm môn'), findsOneWidget);
      expect(find.text('Quét QR'), findsOneWidget);
      expect(find.text('Lịch sử'), findsOneWidget);
    });

    testWidgets('DesktopScaffold hides bottomNavigationBar on desktop screen', (tester) async {
      // Set desktop screen size (1280 x 800)
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopScaffold(
            selectedIndex: 0,
            role: UserRole.student,
            body: const Center(child: Text('Student Desktop Content')),
          ),
        ),
      );

      // Verify NavigationBar is NOT present on desktop
      expect(find.byType(NavigationBar), findsNothing);

      // Desktop sidebar with app logo and navigation items is present
      expect(find.text('Attendly'), findsOneWidget);
    });
  });
}
