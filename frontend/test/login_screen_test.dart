import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/authentication/login_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  GoRouter createRouter() => GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const Scaffold(body: Text('Reset page')),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const Scaffold(body: Text('Register page')),
      ),
    ],
  );

  testWidgets('renders the desktop login composition without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('the World'), findsOneWidget);
    expect(find.text('SMART TRAVEL'), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'supports editing, password visibility, remember me and validation',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = createRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, 'traveler@example.com');
      expect(
        tester.widget<TextField>(fields.first).controller!.text,
        'traveler@example.com',
      );
      expect(tester.widget<TextField>(fields.last).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(tester.widget<TextField>(fields.last).obscureText, isFalse);

      await tester.tap(find.text('Remember me'));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Reset page'), findsOneWidget);
      router.go('/login');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('Register page'), findsOneWidget);
    },
  );

  for (final size in [const Size(768, 1024), const Size(390, 844)]) {
    testWidgets('keeps the login screen usable at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = createRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
