import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otobuzz/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('has 3 onboarding pages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify first page content
      expect(find.text('Catat Kilometer Harian'), findsOneWidget);

      // There should be 3 dot indicators
      // The dots are AnimatedContainers - check they exist
      final dots = find.byType(AnimatedContainer);
      expect(dots, findsNWidgets(3));
    });

    testWidgets('"Selanjutnya" button advances page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // First page shows "Selanjutnya"
      expect(find.text('Selanjutnya'), findsOneWidget);
      expect(find.text('Catat Kilometer Harian'), findsOneWidget);

      // Tap "Selanjutnya"
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      // Should now be on second page
      expect(find.text('Jadwal Perawatan Otomatis'), findsOneWidget);

      // Tap "Selanjutnya" again
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      // Should now be on third page
      expect(find.text('Kelola Armada Lengkap'), findsOneWidget);
    });

    testWidgets('"Mulai Sekarang" shows on last page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to last page
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      // Last page should show "Mulai Sekarang" instead of "Selanjutnya"
      expect(find.text('Mulai Sekarang'), findsOneWidget);
      expect(find.text('Selanjutnya'), findsNothing);
    });
  });
}
