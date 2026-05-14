import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

Widget _hostedIn(Widget child) => MaterialApp(
      theme: AppTheme.materialTheme(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('GradientButton', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(_hostedIn(
        GradientButton(label: 'GO', onPressed: () {}),
      ));
      expect(find.text('GO'), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_hostedIn(
        GradientButton(label: 'TAP', onPressed: () => taps++),
      ));
      await tester.tap(find.text('TAP'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('does nothing when onPressed is null (disabled)',
        (tester) async {
      await tester.pumpWidget(_hostedIn(
        const GradientButton(label: 'OFF', onPressed: null),
      ));
      await tester.tap(find.text('OFF'));
      await tester.pump();
      // No error = no crash; label still visible.
      expect(find.text('OFF'), findsOneWidget);
    });

    testWidgets('renders an icon when provided', (tester) async {
      await tester.pumpWidget(_hostedIn(
        GradientButton(
          label: 'PLAY',
          icon: Icons.play_arrow_rounded,
          onPressed: () {},
        ),
      ));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });

  group('GhostButton', () {
    testWidgets('renders label and invokes onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_hostedIn(
        GhostButton(label: 'GHOST', onPressed: () => taps++),
      ));
      expect(find.text('GHOST'), findsOneWidget);
      await tester.tap(find.text('GHOST'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('disables when onPressed is null', (tester) async {
      await tester.pumpWidget(_hostedIn(
        const GhostButton(label: 'OFF', onPressed: null),
      ));
      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);
    });
  });

  group('PartyBackground', () {
    testWidgets('wraps its child', (tester) async {
      await tester.pumpWidget(_hostedIn(
        const PartyBackground(child: Text('content')),
      ));
      expect(find.text('content'), findsOneWidget);
      expect(find.byType(PartyBackground), findsOneWidget);
    });
  });
}
