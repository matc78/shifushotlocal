/// Mapping of dice-roll combinations to the rule text shown to the player.
///
/// Two dice are unordered: rolling (1,3) is the same as (3,1). We normalize
/// to "min_max" so we only store one entry per combination.
class DiceRules {
  DiceRules._();

  static const Map<String, String> defaults = {
    '1_1': '\nDonner un FU',
    '2_2': '\nDonner 2 SHI',
    '3_3': '\nDonner un surnom,\nSe mettre en couple,\nDonner 3 SHI',
    '4_4': '\nDouble prison\nThème ou mini-jeux',
    '5_5': '\nDonner 5 SHI',
    '6_6': '\nInventer une règle\nDonner 6 SHI',
    '1_2': '\nPas de règle',
    '1_3': '\nPas de règle',
    '1_4': '\nPrison\nJeu du clap',
    '1_5': '\nDonner un surnom\nSe mettre en couple',
    '1_6': '\nBizkit !',
    '2_3': '\nJeu du clap',
    '2_4': '\nPrison\nDonner un surnom\nSe mettre en couple',
    '2_5': '\nBizkit !',
    '2_6': '\nThème ou mini-jeux',
    '3_4': '\nPrison\nBizkit !',
    '3_5': '\nThème ou mini-jeux',
    '3_6': '\nJeu du doigt',
    '4_5': '\nPrison\nJeu du doigt',
    '4_6': '\nPrison',
    '5_6': '\nInventer une règle\nDonner une règle',
  };

  /// Build the canonical lookup key for two dice values. Order-independent:
  /// `keyFor(3, 1) == keyFor(1, 3) == '1_3'`.
  static String keyFor(int a, int b) {
    if (a < 1 || a > 6 || b < 1 || b > 6) {
      throw ArgumentError('Dice values must be in 1..6 (got $a, $b)');
    }
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    return '${lo}_$hi';
  }

  /// Returns the rule text for the given dice roll, or null if the roll has
  /// no defined rule.
  static String? lookup(int a, int b, [Map<String, String>? rules]) {
    return (rules ?? defaults)[keyFor(a, b)];
  }

  /// All 21 distinct combinations of two dice (1..6) in canonical form.
  /// Useful for verifying coverage.
  static Iterable<String> allCombinations() sync* {
    for (var i = 1; i <= 6; i++) {
      for (var j = i; j <= 6; j++) {
        yield '${i}_$j';
      }
    }
  }
}
