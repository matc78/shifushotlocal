import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/pages/home/select_game.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

Future<void> _pumpSelect(WidgetTester tester) async {
  // Tall + wide surface so GridViews lazy-load all tiles AND custom-font
  // fallback (used in tests, since Jaro/Afacad don't load) doesn't overflow.
  tester.view.physicalSize = const Size(600, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.materialTheme(),
    home: const SelectGamePage(),
    onGenerateRoute: (settings) => MaterialPageRoute(
      builder: (_) => Scaffold(body: Text('route:${settings.name}')),
    ),
  ));
}

void main() {
  setUp(() => GuestSession.instance.exitGuestMode());
  tearDown(() => GuestSession.instance.exitGuestMode());

  testWidgets('renders the three section headers', (tester) async {
    await _pumpSelect(tester);
    expect(find.text('EN LOCAL'), findsOneWidget);
    expect(find.text('EN LIGNE'), findsOneWidget);
    expect(find.text('OUTILS & FUN'), findsOneWidget);
  });

  testWidgets('renders the expected game tiles by name', (tester) async {
    await _pumpSelect(tester);
    expect(find.text('Killer'), findsOneWidget);
    expect(find.text('Clicker'), findsOneWidget);
    expect(find.text('Bizkit !'), findsOneWidget);
    expect(find.text('Jeu du débat'), findsOneWidget);
    expect(find.text("Créateur d'équipes"), findsOneWidget);
  });

  testWidgets('section counts match real entries', (tester) async {
    await _pumpSelect(tester);
    expect(find.text('9'), findsOneWidget); // En local
    expect(find.text('1'), findsOneWidget); // En ligne
    expect(find.text('6'), findsOneWidget); // Outils & fun
  });

  testWidgets('online game in guest mode shows "Compte requis"',
      (tester) async {
    GuestSession.instance.enterGuestMode();
    await _pumpSelect(tester);
    expect(find.text('Compte requis'), findsWidgets);
    expect(find.text('Bluff & stratégie'), findsNothing);
  });

  testWidgets('online game in connected mode shows its description',
      (tester) async {
    await _pumpSelect(tester);
    expect(find.text('Bluff & stratégie'), findsOneWidget);
    expect(find.text('Compte requis'), findsNothing);
  });
}
