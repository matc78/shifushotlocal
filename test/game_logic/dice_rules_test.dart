import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/game_logic/dice_rules.dart';

void main() {
  group('DiceRules.keyFor', () {
    test('normalizes order so (a,b) and (b,a) collide', () {
      expect(DiceRules.keyFor(1, 3), DiceRules.keyFor(3, 1));
      expect(DiceRules.keyFor(5, 2), '2_5');
      expect(DiceRules.keyFor(6, 6), '6_6');
    });

    test('rejects out-of-range dice values', () {
      expect(() => DiceRules.keyFor(0, 3), throwsArgumentError);
      expect(() => DiceRules.keyFor(3, 7), throwsArgumentError);
      expect(() => DiceRules.keyFor(-1, 4), throwsArgumentError);
    });
  });

  group('DiceRules.lookup', () {
    test('returns the same rule regardless of dice order', () {
      expect(DiceRules.lookup(1, 6), DiceRules.lookup(6, 1));
      expect(DiceRules.lookup(2, 5), contains('Bizkit'));
    });

    test('returns null for rolls without a defined rule', () {
      // Sanity check: defaults explicitly covers every pair, so this
      // verifies the lookup table swap mechanism.
      const minimal = <String, String>{'1_1': 'snake eyes'};
      expect(DiceRules.lookup(1, 1, minimal), 'snake eyes');
      expect(DiceRules.lookup(2, 3, minimal), isNull);
    });

    test('every defined key matches a real dice combination', () {
      final valid = DiceRules.allCombinations().toSet();
      for (final key in DiceRules.defaults.keys) {
        expect(valid, contains(key),
            reason: '$key is not a valid sorted dice key');
      }
    });

    test('default ruleset covers all 21 combinations', () {
      for (final key in DiceRules.allCombinations()) {
        expect(DiceRules.defaults, contains(key),
            reason: 'Missing rule for $key — players will see null');
      }
    });
  });
}
