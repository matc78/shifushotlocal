import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/routes.dart';

void main() {
  // List every Routes constant we want covered by these checks. Adding a
  // new route → add it here too. Catches "I declared the constant but
  // never wired it" and "I duplicated a path string".
  final all = <String, String>{
    'root': Routes.root,
    'debut': Routes.debut,
    'connexion': Routes.connexion,
    'createAccount': Routes.createAccount,
    'home': Routes.home,
    'selectGame': Routes.selectGame,
    'partyScreen': Routes.partyScreen,
    'userProfile': Routes.userProfile,
    'editProfile': Routes.editProfile,
    'friends': Routes.friends,
    'addFriend': Routes.addFriend,
    'feedback': Routes.feedback,
    'teamGenerator': Routes.teamGenerator,
    'cardDrawer': Routes.cardDrawer,
    'pyramidCard': Routes.pyramidCard,
    'pyramid': Routes.pyramid,
    'pyramidModern': Routes.pyramidModern,
    'shifushotRequest': Routes.shifushotRequest,
    'selectSound': Routes.selectSound,
    'twelveBars': Routes.twelveBars,
    'lobbyScreen': Routes.lobbyScreen,
    'killer': Routes.killer,
    'killerActions': Routes.killerActions,
    'killerSummary': Routes.killerSummary,
    'clickerGame': Routes.clickerGame,
    'diceGame': Routes.diceGame,
    'paperGame': Routes.paperGame,
    'clockGame': Routes.clockGame,
    'reflexGame': Routes.reflexGame,
    'followLine': Routes.followLine,
    'followLineSpeedEasy': Routes.followLineSpeedEasy,
    'followLinePrecisionEasy': Routes.followLinePrecisionEasy,
    'onlineLobby': Routes.onlineLobby,
    'lobbyWaiting': Routes.lobbyWaiting,
    'debateGame': Routes.debateGame,
  };

  group('Routes', () {
    test('every route starts with "/"', () {
      for (final entry in all.entries) {
        expect(entry.value, startsWith('/'),
            reason: 'Routes.${entry.key} = "${entry.value}" must start with /');
      }
    });

    test('every route is unique', () {
      final seen = <String, String>{};
      for (final entry in all.entries) {
        final existing = seen[entry.value];
        expect(existing, isNull,
            reason:
                'Routes.${entry.key} duplicates "${entry.value}" (also Routes.$existing)');
        seen[entry.value] = entry.key;
      }
    });

    test('route paths contain only URL-safe characters', () {
      final pattern = RegExp(r'^/[a-zA-Z0-9_/-]*$');
      for (final entry in all.entries) {
        expect(pattern.hasMatch(entry.value), isTrue,
            reason: 'Routes.${entry.key} = "${entry.value}" has unsafe chars');
      }
    });

    test('no trailing slash (except root)', () {
      for (final entry in all.entries) {
        if (entry.key == 'root') continue;
        expect(entry.value.endsWith('/'), isFalse,
            reason: 'Routes.${entry.key} = "${entry.value}" trails a slash');
      }
    });
  });
}
