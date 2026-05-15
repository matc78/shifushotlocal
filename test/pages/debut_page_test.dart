import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/pages/auth/debut_page.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

Future<void> _pumpDebut(WidgetTester tester) async {
  // DebutPage uses Spacers around fixed-size elements and needs a tall
  // viewport — default 800×600 overflows by ~10px.
  // Wide-enough viewport: custom fonts (Jaro/Afacad) don't load in tests,
  // so text falls back to wider glyphs.
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.materialTheme(),
    home: const DebutPage(),
    onGenerateRoute: (settings) => MaterialPageRoute(
      builder: (_) => Scaffold(body: Text('route:${settings.name}')),
    ),
  ));
}

void main() {
  setUp(() => GuestSession.instance.exitGuestMode());
  tearDown(() => GuestSession.instance.exitGuestMode());

  testWidgets('renders the brand title and both CTAs', (tester) async {
    await _pumpDebut(tester);
    expect(find.text('SHIFUSHOT'), findsOneWidget);
    expect(find.text("C'est parti !"), findsOneWidget);
    expect(find.text('Jouer sans compte'), findsOneWidget);
  });

  testWidgets('"Jouer sans compte" enters guest mode and navigates to home',
      (tester) async {
    await _pumpDebut(tester);
    expect(GuestSession.instance.isGuest, isFalse);

    await tester.tap(find.text('Jouer sans compte'));
    await tester.pumpAndSettle();

    expect(GuestSession.instance.isGuest, isTrue);
    expect(find.text('route:${Routes.home}'), findsOneWidget);
  });
}
