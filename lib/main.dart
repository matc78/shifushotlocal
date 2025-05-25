import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shifushotlocal/Pages/features/pyramid_card.dart';
import 'package:shifushotlocal/Pages/features/sound_category_selection_page.dart';
import 'package:shifushotlocal/Pages/features/twelve_bars_page.dart';
import 'package:shifushotlocal/Pages/local_games/clicker/clicker_game.dart';
import 'package:shifushotlocal/Pages/friends/add_friends_page.dart';
import 'package:shifushotlocal/Pages/features/card_drawer.dart';
import 'package:shifushotlocal/Pages/local_games/follow_line/follow_line_precision_easy_game.dart';
import 'package:shifushotlocal/Pages/local_games/follow_line/follow_line_selection.dart';
import 'package:shifushotlocal/Pages/local_games/follow_line/follow_line_speed_easy_game.dart';
import 'package:shifushotlocal/Pages/local_games/horloge/clock_game_page.dart';
import 'package:shifushotlocal/Pages/connexion/create_account_page.dart';
import 'package:shifushotlocal/Pages/connexion/debut_page.dart';
import 'package:shifushotlocal/Pages/connexion/connexion_page.dart';
import 'package:shifushotlocal/Pages/local_games/bizkit/dice_game_page.dart';
import 'package:shifushotlocal/Pages/local_games/reflex/reflex_game.dart';
import 'package:shifushotlocal/Pages/online_games/lobby_screen_online.dart';
import 'package:shifushotlocal/Pages/online_games/lobby_waiting_screen.dart';
import 'package:shifushotlocal/Pages/online_games/debate_game.dart';
import 'package:shifushotlocal/Pages/profil/edit_profil_page.dart';
import 'package:shifushotlocal/Pages/feedback/feedback_page.dart';
import 'package:shifushotlocal/Pages/friends/friends_page.dart';
import 'package:shifushotlocal/Pages/home_page.dart';
import 'package:shifushotlocal/Pages/local_games/killer/killer_actions_page.dart';
import 'package:shifushotlocal/Pages/local_games/killer/killer_page.dart';
import 'package:shifushotlocal/Pages/local_games/killer/killer_summary_page.dart';
import 'package:shifushotlocal/Pages/local_games/paper/paper_game_page.dart';
import 'package:shifushotlocal/Pages/party_screen.dart';
import 'package:shifushotlocal/Pages/select_game.dart';
import 'package:shifushotlocal/Pages/features/team_generator_page.dart';
import 'package:shifushotlocal/Pages/profil/user_profil_page.dart';
import 'package:shifushotlocal/Pages/local_games/lobby_screen.dart';
import 'package:shifushotlocal/Pages/features/shifushot_request_page.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

Future<void> initializeFirebaseMessaging() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission(alert: true, badge: true, sound: true);
  
  final user = FirebaseAuth.instance.currentUser;
  final token = await fcm.getToken();

  if (user != null && token != null) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await userRef.get();
    if (!doc.exists) {
      // Crée un document minimal si inexistant
      await userRef.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'fcmToken': token,
        'notifications': {
          'enabled': true,
          'friend_requests': true,
          'shifushot_requests': true,
        },
        'friends': [],
        'friend_requests': [],
        'pending_approval': [],
      });
    } else {
      // Sinon, juste mettre à jour le token
      await userRef.update({'fcmToken': token});
    }
  }

  fcm.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': newToken,
      });
    }
  });

  FirebaseMessaging.onMessage.listen((message) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? 'Nouveau message'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_), child: const Text("OK")),
        ],
      ),
    );
  });
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const AuthWrapper(),
      routes: {
        '/debutpage': (_) => const DebutPage(),
        '/connexion': (_) => const ConnexionPage(),
        '/createAccount': (_) => const CreateAccountPage(),
        '/homepage': (_) => const HomePage(),
        '/user_profile_page': (_) => const UserProfilePage(),
        '/Pages/lobby_screen': (_) => const LobbyScreen(),
        '/friends': (_) => const FriendsPage(),
        '/addFriend': (_) => const AddFriendsPage(),
        '/editProfile': (_) => const EditProfilePage(),
        '/teamGenerator': (_) => const TeamGeneratorPage(),
        '/select_game': (_) => const SelectGamePage(),
        '/killer': (_) => const KillerPage(),
        '/killerActions': (context) => KillerActionsPage(players: ModalRoute.of(context)!.settings.arguments as List<String>),
        '/killerSummary': (context) => KillerSummaryPage(playerData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
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
          } else {
            return const Scaffold(body: Center(child: Text("Erreur : Arguments invalides.")));
          }
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
          return OnlineLobbyScreen(gameName: gameName ?? "Jeu inconnu");
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
          } else {
            return const Scaffold(body: Center(child: Text("Erreur : Aucun lobbyId fourni")));
          }
        },
        '/pyramid_card': (_) => const PyramidCardPage(),
        '/shifushot_request': (context) => const ShifushotRequestPage(),
        '/select_sound': (context) => SoundCategorySelectionPage(),
        '/twelve_bars': (context) => const TwelveBarsPage(),
        '/reflex_game': (context) => const ReflexGamePage(),
        '/follow_line': (context) => const FollowLineModeSelector(),
        '/follow_line_speed_easy': (context) => const FollowLineSpeedEasy(),
        '/follow_line_precision_easy': (context) => const FollowLinePrecisionEasy(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // 🔥 Initialiser FCM après connexion
          initializeFirebaseMessaging(); // ✅ Maintenant ici
          return const HomePage();
        } else {
          return const DebutPage();
        }
      },
    );
  }
}
