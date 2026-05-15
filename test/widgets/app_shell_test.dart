import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

Widget _hosted(Widget child) => MaterialApp(
      theme: AppTheme.materialTheme(),
      home: child,
    );

void main() {
  group('AppShell', () {
    testWidgets('renders the title and the child', (tester) async {
      await tester.pumpWidget(_hosted(
        const AppShell(title: 'My title', child: Text('hello')),
      ));
      expect(find.text('My title'), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('shows a back arrow by default and hides it on demand',
        (tester) async {
      await tester.pumpWidget(_hosted(
        const AppShell(title: 't', child: SizedBox.shrink()),
      ));
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      await tester.pumpWidget(_hosted(
        const AppShell(
          title: 't',
          showBack: false,
          child: SizedBox.shrink(),
        ),
      ));
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('back button invokes the onBack override', (tester) async {
      var clicked = 0;
      await tester.pumpWidget(_hosted(
        AppShell(
          title: 't',
          onBack: () => clicked++,
          child: const SizedBox.shrink(),
        ),
      ));
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      expect(clicked, 1);
    });

    testWidgets('renders trailing actions when provided', (tester) async {
      await tester.pumpWidget(_hosted(
        AppShell(
          title: 't',
          actions: [
            IconButton(
                icon: const Icon(Icons.settings_rounded), onPressed: () {}),
          ],
          child: const SizedBox.shrink(),
        ),
      ));
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('shows icon + title + subtitle', (tester) async {
      await tester.pumpWidget(_hosted(
        const Scaffold(
          body: EmptyState(
            icon: Icons.group_outlined,
            title: 'Nothing here',
            subtitle: 'Add some friends',
          ),
        ),
      ));
      expect(find.byIcon(Icons.group_outlined), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add some friends'), findsOneWidget);
    });

    testWidgets('omits subtitle when not given', (tester) async {
      await tester.pumpWidget(_hosted(
        const Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Empty',
          ),
        ),
      ));
      expect(find.text('Empty'), findsOneWidget);
      // No other text widget besides the title.
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('SectionCard', () {
    testWidgets('wraps its child', (tester) async {
      await tester.pumpWidget(_hosted(
        const Scaffold(
          body: SectionCard(child: Text('content')),
        ),
      ));
      expect(find.text('content'), findsOneWidget);
      expect(find.byType(SectionCard), findsOneWidget);
    });
  });

  group('Skeleton placeholders', () {
    testWidgets('SkeletonBlock builds without errors', (tester) async {
      await tester.pumpWidget(_hosted(
        const Scaffold(body: SkeletonBlock()),
      ));
      expect(find.byType(SkeletonBlock), findsOneWidget);
    });

    testWidgets(
        'SkeletonListTile renders three skeleton blocks (avatar + 2 lines)',
        (tester) async {
      await tester.pumpWidget(_hosted(
        const Scaffold(body: SkeletonListTile()),
      ));
      expect(find.byType(SkeletonBlock), findsNWidgets(3));
    });
  });
}
