import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/pages/home/home_page.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  // Wide-enough viewport: custom fonts (Jaro/Afacad) don't load in tests,
  // so text falls back to wider glyphs.
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.materialTheme(),
    home: const HomePage(),
    onGenerateRoute: (settings) => MaterialPageRoute(
      builder: (_) => Scaffold(body: Text('route:${settings.name}')),
    ),
  ));
}

void main() {
  setUp(() => GuestSession.instance.exitGuestMode());
  tearDown(() => GuestSession.instance.exitGuestMode());

  testWidgets('renders the brand title and the primary CTA', (tester) async {
    await _pumpHome(tester);
    expect(find.text('SHIFUSHOT'), findsOneWidget);
    expect(find.text('Lancer une partie'), findsOneWidget);
  });

  testWidgets('hides the guest banner in connected mode', (tester) async {
    await _pumpHome(tester);
    expect(find.text('Mode invité — jeux locaux uniquement'), findsNothing);
  });

  testWidgets('shows the guest banner in guest mode', (tester) async {
    GuestSession.instance.enterGuestMode();
    await _pumpHome(tester);
    expect(find.text('Mode invité — jeux locaux uniquement'), findsOneWidget);
  });

  testWidgets('"Lancer une partie" navigates to select_game', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Lancer une partie'));
    await tester.pumpAndSettle();
    expect(find.text('route:${Routes.selectGame}'), findsOneWidget);
  });

  testWidgets('the "Soon" button is disabled (tap is a no-op)', (tester) async {
    await _pumpHome(tester);
    expect(find.text('Soon — Mode soirée'), findsOneWidget);
    await tester.tap(find.text('Soon — Mode soirée'));
    await tester.pump();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Feedback bottom action navigates to feedback', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    expect(find.text('route:${Routes.feedback}'), findsOneWidget);
  });

  testWidgets('Soirée bottom action navigates to party_screen', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Soirée'));
    await tester.pumpAndSettle();
    expect(find.text('route:${Routes.partyScreen}'), findsOneWidget);
  });
}
