import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:shifushotlocal/services/firebase_messaging_service.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
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
        '/debutpage': (_) => const DebutPage(),
        '/connexion': (_) => const ConnexionPage(),
        '/createAccount': (_) => const CreateAccountPage(),
        '/homepage': (_) => const HomePage(),
        '/user_profile_page': (_) => const UserProfilePage(),
        '/lobby_screen': (_) => const LobbyScreen(),
        '/friends': (_) => const FriendsPage(),
        '/addFriend': (_) => const AddFriendsPage(),
        '/editProfile': (_) => const EditProfilePage(),
        '/teamGenerator': (_) => const TeamGeneratorPage(),
        '/select_game': (_) => const SelectGamePage(),
        '/killer': (_) => const KillerPage(),
        '/killerActions': (context) => KillerActionsPage(
              players: ModalRoute.of(context)!.settings.arguments as List<String>,
            ),
        '/killerSummary': (context) => KillerSummaryPage(
              playerData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
            ),
        '/clicker_game': (_) => const ClickerGame(),
        '/dice_game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String) {
            return DiceGamePage(players: [args], remainingGames: const ['/homepage']);
          } else if (args is Map<String, dynamic>) {
            return DiceGamePage(
              players: List<String>.from(args['players']),
              remainingGames: List<String>.from(args['remainingGames']),
            );
          }
          return const Scaffold(body: Center(child: Text('Erreur : Arguments invalides.')));
        },
        '/paper_game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaperGamePage(
            players: List<String>.from(args['players']),
            remainingGames: List<String>.from(args['remainingGames']),
          );
        },
        '/party_screen': (_) => const PartyScreen(),
        '/feedback_page': (_) => const FeedbackPage(),
        '/clock_game': (_) => const ClockGameScreen(),
        '/cardDrawer': (_) => const CardDrawerPage(),
        '/online_lobby': (context) {
          final gameName = ModalRoute.of(context)!.settings.arguments as String?;
          return OnlineLobbyScreen(gameName: gameName ?? 'Jeu inconnu');
        },
        '/lobby_waiting': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return LobbyWaitingScreen(
            lobbyId: args['lobbyId'] as String,
            isHost: args['isHost'] as bool,
            gameRoute: args['gameRoute'] as String,
          );
        },
        '/debate_game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic> && args.containsKey('lobbyId')) {
            return DebateGameScreen(lobbyId: args['lobbyId'] as String);
          }
          return const Scaffold(body: Center(child: Text('Erreur : Aucun lobbyId fourni')));
        },
        '/pyramid_card': (_) => const PyramidCardPage(),
        '/pyramid': (_) => const PyramidePage(),
        '/pyramid_modern': (_) => const PyramideModernePage(),
        '/shifushot_request': (_) => const ShifushotRequestPage(),
        '/select_sound': (_) => SoundCategorySelectionPage(),
        '/twelve_bars': (_) => const TwelveBarsPage(),
        '/reflex_game': (_) => const ReflexGamePage(),
        '/follow_line': (_) => const FollowLineModeSelector(),
        '/follow_line_speed_easy': (_) => const FollowLineSpeedEasy(),
        '/follow_line_precision_easy': (_) => const FollowLinePrecisionEasy(),
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
