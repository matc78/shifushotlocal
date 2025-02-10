import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/Pages/jeu1.dart';
import 'package:shifushotlocal/add_friends_page.dart';
import 'package:shifushotlocal/clock_game_page.dart';
import 'package:shifushotlocal/create_account_page.dart';
import 'package:shifushotlocal/debut_page.dart';
import 'package:shifushotlocal/connexion_page.dart';
import 'package:shifushotlocal/dice_game_page.dart';
import 'package:shifushotlocal/edit_profil_page.dart';
import 'package:shifushotlocal/feedback_page.dart';
import 'package:shifushotlocal/friends_page.dart';
import 'package:shifushotlocal/home_page.dart';
import 'package:shifushotlocal/killer_actions_page.dart';
import 'package:shifushotlocal/killer_page.dart';
import 'package:shifushotlocal/killer_summary_page.dart';
import 'package:shifushotlocal/paper_game_page.dart';
import 'package:shifushotlocal/party_screen.dart';
import 'package:shifushotlocal/select_game.dart';
import 'package:shifushotlocal/team_generator_page.dart';
import 'package:shifushotlocal/user_profil_page.dart';
import 'package:shifushotlocal/Pages/lobby_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), // Utilisation d'un wrapper pour la navigation
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
            // Mode "Jeu" : aucun remainingGames, juste un seul joueur et retour à la page d'accueil
            return DiceGamePage(
              players: [args], // Passer le nom du joueur
              remainingGames: ['/homepage'], // Redirection vers l'accueil après
            );
          } else if (args is Map<String, dynamic>) {
            // Mode "Soirée" : récupération des joueurs et des jeux restants
            return DiceGamePage(
              players: args['players'] as List<String>,
              remainingGames: args['remainingGames'] as List<String>,
            );
          } else {
            // Gestion d'erreurs (aucun argument valide)
            return const Scaffold(
              body: Center(child: Text("Erreur : Arguments invalides.")),
            );
          }
        },
        '/paper_game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final players = args['players'] as List<String>;
          final remainingGames = args['remainingGames'] as List<String>;
          return PaperGamePage(players: players, remainingGames: remainingGames);
        },
        '/party_screen': (context) => const PartyScreen(),
        '/feedback_page': (context) => const FeedbackPage(),
        '/clock_game': (context) => const ClockGameScreen(),
      },
    );
  }
}

// Wrapper pour vérifier si l'utilisateur est connecté
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // Si l'utilisateur est connecté, diriger vers la HomePage
          return const HomePage();
        } else {
          // Sinon, diriger vers la page de connexion
          return const DebutPage();
        }
      },
    );
  }
}
