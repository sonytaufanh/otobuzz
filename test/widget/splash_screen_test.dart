import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otobuzz/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SplashScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows OtoBuzz text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.text('OtoBuzz'), findsOneWidget);

      // Pump past the timer to avoid pending timer assertion
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('shows Fleet Maintenance Tracker subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.text('Fleet Maintenance Tracker'), findsOneWidget);

      // Pump past the timer to avoid pending timer assertion
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('shows car icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.byIcon(Icons.directions_car), findsOneWidget);

      // Pump past the timer to avoid pending timer assertion
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('navigates after delay', (tester) async {
      // Use a flag to indicate onboarding not completed so it navigates to
      // OnboardingScreen (which doesn't need BLoC providers)
      SharedPreferences.setMockInitialValues({'onboarding_completed': false});

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify we start at the splash screen
      expect(find.text('OtoBuzz'), findsOneWidget);

      // Advance past the 1500ms delay and let navigation complete
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // After navigation, splash text should be gone (navigated to onboarding)
      expect(find.text('OtoBuzz'), findsNothing);
    });
  });
}
