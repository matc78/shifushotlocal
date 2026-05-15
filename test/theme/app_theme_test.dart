import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('exposes a singleton dark palette', () {
      final a = AppTheme.of(_fakeContext);
      final b = AppTheme.of(_fakeContext);
      expect(identical(a, b), isTrue,
          reason: 'AppTheme.of should return the same instance');
    });

    test('palette is dark (background luminance < 0.1)', () {
      final theme = AppTheme.of(_fakeContext);
      expect(theme.background.computeLuminance(), lessThan(0.1));
      expect(theme.surface.computeLuminance(), lessThan(0.2));
    });

    test('text on background passes a minimal contrast check', () {
      final theme = AppTheme.of(_fakeContext);
      final bg = theme.background.computeLuminance();
      final fg = theme.textPrimary.computeLuminance();
      // Naive ratio: (max+0.05)/(min+0.05). WCAG AA body text is 4.5.
      final ratio = (fg + 0.05) / (bg + 0.05);
      expect(ratio, greaterThan(4.5));
    });

    test('materialTheme is Material 3 and dark', () {
      final data = AppTheme.materialTheme();
      expect(data.useMaterial3, isTrue);
      expect(data.brightness, Brightness.dark);
      expect(data.scaffoldBackgroundColor,
          equals(AppTheme.of(_fakeContext).background));
    });

    test('brandGradient has 2 stops in the pink→violet family', () {
      final gradient = AppTheme.of(_fakeContext).brandGradient;
      expect(gradient.colors.length, 2);
      // First color: hue closer to pink/magenta
      final first = HSVColor.fromColor(gradient.colors.first);
      expect(first.hue, inInclusiveRange(280, 360));
      // Second color: hue in the violet range
      final second = HSVColor.fromColor(gradient.colors.last);
      expect(second.hue, inInclusiveRange(240, 320));
    });

    test('radii increase: sm < md < lg < pill', () {
      expect(AppTheme.radiusSm, lessThan(AppTheme.radiusMd));
      expect(AppTheme.radiusMd, lessThan(AppTheme.radiusLg));
      expect(AppTheme.radiusLg, lessThan(AppTheme.radiusPill));
    });
  });
}

/// AppTheme.of currently ignores its context argument; passing the bare type
/// keeps the test pure and avoids needing a real BuildContext.
BuildContext get _fakeContext => _FakeBuildContext();

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
