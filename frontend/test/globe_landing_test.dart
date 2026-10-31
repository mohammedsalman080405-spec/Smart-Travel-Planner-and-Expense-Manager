import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/globe_provider.dart';
import 'package:frontend/providers/hotel_provider.dart';
import 'package:frontend/screens/globe_home/globe_home_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('opens on a clean global globe without hotel results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => GlobeProvider()),
              ChangeNotifierProvider(create: (_) => HotelProvider()),
            ],
            child: const GlobeHomeScreen(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Realistic 3D Earth Globe (WebGL)'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.text('Map'), findsNothing);
    expect(find.text('List'), findsNothing);
    expect(find.textContaining('Verified Hotels'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
