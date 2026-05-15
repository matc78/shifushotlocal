import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/pages/auth/connexion_page.dart';
import 'package:shifushotlocal/pages/auth/create_account_page.dart';
import 'package:shifushotlocal/pages/auth/debut_page.dart';
import 'package:shifushotlocal/pages/games/features/card_drawer.dart';
import 'package:shifushotlocal/pages/games/features/pyramid_card.dart';
import 'package:shifushotlocal/pages/games/features/pyramide.dart';
import 'package:shifushotlocal/pages/games/features/pyramide_moderne.dart';
import 'package:shifushotlocal/pages/games/features/shifushot_request_page.dart';
import 'package:shifushotlocal/pages/games/features/sound_category_selection_page.dart';
import 'package:shifushotlocal/pages/games/features/team_generator_page.dart';
import 'package:shifushotlocal/pages/games/features/twelve_bars_page.dart';
import 'package:shifushotlocal/pages/games/local/bizkit/dice_game_page.dart';
import 'package:shifushotlocal/pages/games/local/clicker/clicker_game.dart';
import 'package:shifushotlocal/pages/games/local/follow_line/follow_line_precision_easy_game.dart';
import 'package:shifushotlocal/pages/games/local/follow_line/follow_line_selection.dart';
import 'package:shifushotlocal/pages/games/local/follow_line/follow_line_speed_easy_game.dart';
import 'package:shifushotlocal/pages/games/local/horloge/clock_game_page.dart';
import 'package:shifushotlocal/pages/games/local/killer/killer_actions_page.dart';
import 'package:shifushotlocal/pages/games/local/killer/killer_page.dart';
import 'package:shifushotlocal/pages/games/local/killer/killer_summary_page.dart';
import 'package:shifushotlocal/pages/games/local/lobby_screen.dart';
import 'package:shifushotlocal/pages/games/local/paper/paper_game_page.dart';
import 'package:shifushotlocal/pages/games/local/reflex/reflex_game.dart';
import 'package:shifushotlocal/pages/games/online/debate_game.dart';
import 'package:shifushotlocal/pages/games/online/lobby_screen_online.dart';
import 'package:shifushotlocal/pages/games/online/lobby_waiting_screen.dart';
import 'package:shifushotlocal/pages/home/home_page.dart';
import 'package:shifushotlocal/pages/home/party_screen.dart';
import 'package:shifushotlocal/pages/home/select_game.dart';
import 'package:shifushotlocal/pages/profile/edit_profile_page.dart';
import 'package:shifushotlocal/pages/profile/user_profile_page.dart';
import 'package:shifushotlocal/pages/social/add_friends_page.dart';
import 'package:shifushotlocal/pages/social/feedback_page.dart';
import 'package:shifushotlocal/pages/social/friends_page.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/services/firebase_messaging_service.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Run everything inside a guarded zone so async errors that escape the
  // Flutter framework still reach Crashlytics.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0E0B1F),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Send crashes/uncaught errors to Crashlytics. Disabled in debug so we
    // don't pollute the dashboard with local stack traces.
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(const MainApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.materialTheme(),
      home: const AuthWrapper(),
      routes: {
        Routes.debut: (_) => const DebutPage(),
        Routes.connexion: (_) => const ConnexionPage(),
        Routes.createAccount: (_) => const CreateAccountPage(),
        Routes.home: (_) => const HomePage(),
        Routes.userProfile: (_) => const UserProfilePage(),
        Routes.lobbyScreen: (_) => const LobbyScreen(),
        Routes.friends: (_) => const FriendsPage(),
        Routes.addFriend: (_) => const AddFriendsPage(),
        Routes.editProfile: (_) => const EditProfilePage(),
        Routes.teamGenerator: (_) => const TeamGeneratorPage(),
        Routes.selectGame: (_) => const SelectGamePage(),
        Routes.killer: (_) => const KillerPage(),
        Routes.killerActions: (context) => KillerActionsPage(
              players: ModalRoute.of(context)!.settings.arguments as List<String>,
            ),
        Routes.killerSummary: (context) => KillerSummaryPage(
              playerData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
            ),
        Routes.clickerGame: (_) => const ClickerGame(),
        Routes.diceGame: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String) {
            return DiceGamePage(players: [args], remainingGames: const [Routes.home]);
          } else if (args is Map<String, dynamic>) {
            return DiceGamePage(
              players: List<String>.from(args['players']),
              remainingGames: List<String>.from(args['remainingGames']),
            );
          }
          return const Scaffold(body: Center(child: Text('Erreur : Arguments invalides.')));
        },
        Routes.paperGame: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaperGamePage(
            players: List<String>.from(args['players']),
            remainingGames: List<String>.from(args['remainingGames']),
          );
        },
        Routes.partyScreen: (_) => const PartyScreen(),
        Routes.feedback: (_) => const FeedbackPage(),
        Routes.clockGame: (_) => const ClockGameScreen(),
        Routes.cardDrawer: (_) => const CardDrawerPage(),
        Routes.onlineLobby: (context) {
          final gameName = ModalRoute.of(context)!.settings.arguments as String?;
          return OnlineLobbyScreen(gameName: gameName ?? 'Jeu inconnu');
        },
        Routes.lobbyWaiting: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return LobbyWaitingScreen(
            lobbyId: args['lobbyId'] as String,
            isHost: args['isHost'] as bool,
            gameRoute: args['gameRoute'] as String,
          );
        },
        Routes.debateGame: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic> && args.containsKey('lobbyId')) {
            return DebateGameScreen(lobbyId: args['lobbyId'] as String);
          }
          return const Scaffold(body: Center(child: Text('Erreur : Aucun lobbyId fourni')));
        },
        Routes.pyramidCard: (_) => const PyramidCardPage(),
        Routes.pyramid: (_) => const PyramidePage(),
        Routes.pyramidModern: (_) => const PyramideModernePage(),
        Routes.shifushotRequest: (_) => const ShifushotRequestPage(),
        Routes.selectSound: (_) => SoundCategorySelectionPage(),
        Routes.twelveBars: (_) => const TwelveBarsPage(),
        Routes.reflexGame: (_) => const ReflexGamePage(),
        Routes.followLine: (_) => const FollowLineModeSelector(),
        Routes.followLineSpeedEasy: (_) => const FollowLineSpeedEasy(),
        Routes.followLinePrecisionEasy: (_) => const FollowLinePrecisionEasy(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    GuestSession.instance.addListener(_onGuestChanged);
  }

  @override
  void dispose() {
    GuestSession.instance.removeListener(_onGuestChanged);
    super.dispose();
  }

  void _onGuestChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          FirebaseMessagingService.instance.initializeForUser(navigatorKey);
          return const HomePage();
        }
        if (GuestSession.instance.isGuest) {
          return const HomePage();
        }
        FirebaseMessagingService.instance.reset();
        return const DebutPage();
      },
    );
  }
}
