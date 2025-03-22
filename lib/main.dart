import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shifushotlocal/Pages/features/pyramid_card.dart';
import 'package:shifushotlocal/Pages/local_games/clicker/jeu1.dart';
import 'package:shifushotlocal/Pages/friends/add_friends_page.dart';
import 'package:shifushotlocal/Pages/features/card_drawer.dart';
import 'package:shifushotlocal/Pages/local_games/horloge/clock_game_page.dart';
import 'package:shifushotlocal/Pages/connexion/create_account_page.dart';
import 'package:shifushotlocal/Pages/connexion/debut_page.dart';
import 'package:shifushotlocal/Pages/connexion/connexion_page.dart';
import 'package:shifushotlocal/Pages/local_games/bizkit/dice_game_page.dart';
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
import 'firebase_options.dart';

// Définir une clé de navigation globale
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Force l'orientation en mode portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser Firebase Messaging
  await initializeFirebaseMessaging();

  runApp(const MainApp());
}

// Fonction pour initialiser Firebase Messaging
Future<void> initializeFirebaseMessaging() async {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Demander l'autorisation pour les notifications (iOS)
  // ignore: unused_local_variable
  NotificationSettings settings = await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Récupérer le token FCM
  String? token = await _firebaseMessaging.getToken();
  if (token != null) {
    print("FCM Token: $token");

    // Stocker le token dans Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  // Écouter les nouveaux tokens (au cas où il change)
  _firebaseMessaging.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': newToken});
    }
  });

  // Configurer la gestion des notifications en premier plan
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notification reçue: ${message.notification?.title}');
    // Afficher une alerte ou mettre à jour l'UI
    showDialog(
      context: navigatorKey.currentContext!, // Utilisez une clé de navigation si nécessaire
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? 'Nouveau message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
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
      navigatorKey: navigatorKey, // Utiliser la clé de navigation globale
      home: const AuthWrapper(), // Vérification de l'authentification
      routes: {
        '/connexion': (context) => const ConnexionPage(),
        '/createAccount': (context) => const CreateAccountPage(),
        '/homepage': (context) => const HomePage(),
        '/user_profile_page': (context) => const UserProfilePage(),
        '/Pages/lobby_screen': (context) => const LobbyScreen(),
        '/friends': (context) => const FriendsPage(),
        '/addFriend': (context) => const AddFriendsPage(),
        '/editProfile': (context) => const EditProfilePage(),
        '/teamGenerator': (context) => const TeamGeneratorPage(),
        '/select_game': (context) => const SelectGamePage(),
        '/killer': (context) => const KillerPage(),
        
        '/killerActions': (context) {
          final players = ModalRoute.of(context)!.settings.arguments as List<String>;
          return KillerActionsPage(players: players);
        },
        
        '/killerSummary': (context) {
          final playerData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return KillerSummaryPage(playerData: playerData);
        },
        
        '/jeu1': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return Jeu1(
            players: args['players'] as List<String>,
            remainingGames: args['remainingGames'] as List<String>,
          );
        },
        
        '/dice_game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String) {
            return DiceGamePage(players: [args], remainingGames: const ['/homepage']);
          } else if (args is Map<String, dynamic>) {
            return DiceGamePage(
              players: args['players'] as List<String>,
              remainingGames: args['remainingGames'] as List<String>,
            );
          } else {
            return const Scaffold(
              body: Center(child: Text("Erreur : Arguments invalides.")),
            );
          }
        },
        
        '/paper_game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaperGamePage(
            players: args['players'] as List<String>,
            remainingGames: args['remainingGames'] as List<String>,
          );
        },
        
        '/party_screen': (context) => const PartyScreen(),
        '/feedback_page': (context) => const FeedbackPage(),
        '/clock_game': (context) => const ClockGameScreen(),
        '/cardDrawer': (context) => const CardDrawerPage(),

        // 🔹 **Jeux en ligne**
        '/online_lobby': (context) {
          final gameName = ModalRoute.of(context)!.settings.arguments as String?;
          return gameName != null
              ? OnlineLobbyScreen(gameName: gameName)
              : const OnlineLobbyScreen(gameName: "Jeu inconnu");
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
            return const Scaffold(
              body: Center(child: Text("Erreur : Aucun lobbyId fourni")),
            );
          }
        },
        '/pyramid_card': (context) => const PyramidCardPage(),
      },
    );
  }
}

// 🔹 **Vérification de l'authentification**
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
          return const HomePage();
        } else {
          return const DebutPage();
        }
      },
    );
  }
}