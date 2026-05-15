import 'dart:math';

/// Killer game target assignment.
///
/// Each player is assigned to "kill" exactly one other player. Implemented
/// as a circular chain after shuffling, which guarantees:
///   1. Every player has exactly one target.
///   2. Every player is the target of exactly one other player.
///   3. No player targets themselves.
///
/// Returns a `{player: target}` map. With an optional [random], the result
/// is deterministic for tests.
class KillerAssignment {
  KillerAssignment._();

  static Map<String, String> assign(
    List<String> players, {
    Random? random,
  }) {
    if (players.length < 2) {
      throw ArgumentError(
          'Killer needs at least 2 players (got ${players.length})');
    }
    final shuffled = List<String>.from(players)..shuffle(random);
    final result = <String, String>{};
    for (var i = 0; i < shuffled.length; i++) {
      final current = shuffled[i];
      final next = shuffled[(i + 1) % shuffled.length];
      result[current] = next;
    }
    return result;
  }
}
