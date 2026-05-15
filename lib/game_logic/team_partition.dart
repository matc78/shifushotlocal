import 'dart:math';

/// Pure logic for partitioning a list of players into teams of a target size.
///
/// Behavior:
/// - The last team may be smaller if the player count isn't divisible.
/// - With an optional [random], the partition is deterministic (handy for tests).
/// - Returns an empty map if [players] is empty or [perTeam] is < 1.
class TeamPartition {
  TeamPartition._();

  static Map<int, List<String>> partition(
    List<String> players, {
    required int perTeam,
    Random? random,
  }) {
    if (players.isEmpty || perTeam < 1) return {};
    final shuffled = List<String>.from(players)..shuffle(random);
    final result = <int, List<String>>{};
    final teamCount = (shuffled.length / perTeam).ceil();
    for (var i = 0; i < teamCount; i++) {
      final size = shuffled.length < perTeam ? shuffled.length : perTeam;
      result[i] = shuffled.take(size).toList();
      shuffled.removeRange(0, size);
    }
    return result;
  }
}
