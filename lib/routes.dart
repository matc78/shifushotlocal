/// All named routes used by MaterialApp.
///
/// Use these constants instead of typing route strings inline — that way
/// a typo becomes a compile error instead of a silent navigation failure,
/// and renaming a route shows up in find-references.
class Routes {
  Routes._();

  // Root / auth
  static const String root = '/';
  static const String debut = '/debutpage';
  static const String connexion = '/connexion';
  static const String createAccount = '/createAccount';

  // Home / shell
  static const String home = '/homepage';
  static const String selectGame = '/select_game';
  static const String partyScreen = '/party_screen';
  static const String userProfile = '/user_profile_page';
  static const String editProfile = '/editProfile';
  static const String friends = '/friends';
  static const String addFriend = '/addFriend';
  static const String feedback = '/feedback_page';

  // Features
  static const String teamGenerator = '/teamGenerator';
  static const String cardDrawer = '/cardDrawer';
  static const String pyramidCard = '/pyramid_card';
  static const String pyramid = '/pyramid';
  static const String pyramidModern = '/pyramid_modern';
  static const String shifushotRequest = '/shifushot_request';
  static const String selectSound = '/select_sound';
  static const String twelveBars = '/twelve_bars';

  // Local games
  static const String lobbyScreen = '/lobby_screen';
  static const String killer = '/killer';
  static const String killerActions = '/killerActions';
  static const String killerSummary = '/killerSummary';
  static const String clickerGame = '/clicker_game';
  static const String diceGame = '/dice_game';
  static const String paperGame = '/paper_game';
  static const String clockGame = '/clock_game';
  static const String reflexGame = '/reflex_game';
  static const String followLine = '/follow_line';
  static const String followLineSpeedEasy = '/follow_line_speed_easy';
  static const String followLinePrecisionEasy = '/follow_line_precision_easy';

  // Online
  static const String onlineLobby = '/online_lobby';
  static const String lobbyWaiting = '/lobby_waiting';
  static const String debateGame = '/debate_game';
}
