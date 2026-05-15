import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/game_logic/team_partition.dart';

void main() {
  group('TeamPartition.partition', () {
    test('empty players → empty result', () {
      expect(TeamPartition.partition([], perTeam: 2), isEmpty);
    });

    test('perTeam < 1 → empty result', () {
      expect(TeamPartition.partition(['a', 'b'], perTeam: 0), isEmpty);
    });

    test('divides evenly when count is a multiple of perTeam', () {
      final teams = TeamPartition.partition(
        ['a', 'b', 'c', 'd'],
        perTeam: 2,
        random: Random(1),
      );
      expect(teams.length, 2);
      expect(teams[0]!.length, 2);
      expect(teams[1]!.length, 2);
    });

    test('last team is smaller when not divisible', () {
      final teams = TeamPartition.partition(
        ['a', 'b', 'c', 'd', 'e'],
        perTeam: 2,
        random: Random(7),
      );
      expect(teams.length, 3);
      expect(teams[2]!.length, 1);
    });

    test('every player appears exactly once across teams', () {
      final players = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
      final teams = TeamPartition.partition(
        players,
        perTeam: 3,
        random: Random(42),
      );
      final flat = teams.values.expand((t) => t).toList()..sort();
      expect(flat, equals(players..sort()));
    });

    test('seeded random gives deterministic output', () {
      final a = TeamPartition.partition(
        ['a', 'b', 'c', 'd'],
        perTeam: 2,
        random: Random(123),
      );
      final b = TeamPartition.partition(
        ['a', 'b', 'c', 'd'],
        perTeam: 2,
        random: Random(123),
      );
      expect(a, equals(b));
    });
  });
}
