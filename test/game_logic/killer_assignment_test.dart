import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/game_logic/killer_assignment.dart';

void main() {
  group('KillerAssignment.assign', () {
    test('throws when given fewer than 2 players', () {
      expect(() => KillerAssignment.assign([]), throwsArgumentError);
      expect(() => KillerAssignment.assign(['solo']), throwsArgumentError);
    });

    test('every player gets exactly one target', () {
      final result = KillerAssignment.assign(
        ['a', 'b', 'c', 'd'],
        random: Random(1),
      );
      expect(result.keys.toSet(), {'a', 'b', 'c', 'd'});
    });

    test('every player is targeted exactly once', () {
      final result = KillerAssignment.assign(
        ['a', 'b', 'c', 'd', 'e'],
        random: Random(2),
      );
      expect(result.values.toSet(), result.keys.toSet());
      expect(result.values.toList().length, result.values.toSet().length);
    });

    test('no one targets themselves', () {
      final result = KillerAssignment.assign(
        ['alice', 'bob', 'carol', 'dave'],
        random: Random(99),
      );
      for (final entry in result.entries) {
        expect(entry.key, isNot(entry.value),
            reason: '${entry.key} cannot target themselves');
      }
    });

    test('forms one closed chain (no cycles of length < n)', () {
      final players = ['a', 'b', 'c', 'd', 'e', 'f'];
      final result = KillerAssignment.assign(players, random: Random(5));
      // Walking from any starting player must hit all n nodes before looping.
      final visited = <String>{};
      var current = players.first;
      for (var i = 0; i < players.length; i++) {
        expect(visited.add(current), isTrue,
            reason: 'Hit a sub-cycle at step $i: $current already visited');
        current = result[current]!;
      }
      expect(current, players.first,
          reason: 'Chain must close back to start after n steps');
    });

    test('seeded random gives deterministic output', () {
      final a =
          KillerAssignment.assign(['a', 'b', 'c', 'd'], random: Random(7));
      final b =
          KillerAssignment.assign(['a', 'b', 'c', 'd'], random: Random(7));
      expect(a, equals(b));
    });
  });
}
