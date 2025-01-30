import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/add_friends_page.dart';
import 'package:shifushotlocal/create_account_page.dart';
import 'package:shifushotlocal/debut_page.dart';
import 'package:shifushotlocal/connexion_page.dart'; // Importez la page de connexion
import 'package:shifushotlocal/edit_profil_page.dart';
import 'package:shifushotlocal/friends_page.dart';
import 'package:shifushotlocal/home_page.dart';
import 'package:shifushotlocal/killer_actions_page.dart';
import 'package:shifushotlocal/killer_page.dart';
import 'package:shifushotlocal/killer_summary_page.dart';
import 'package:shifushotlocal/select_game.dart';
import 'package:shifushotlocal/team_generator_page.dart';
import 'package:shifushotlocal/user_profil_page.dart';
import 'package:shifushotlocal/Pages/lobby_screen.dart';
import 'firebase_options.dart'; // Assurez-vous que ce fichier est correctement généré

Future<void> main() async {
  // Ajoutez cette ligne pour initialiser les bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisez Firebase
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
      debugShowCheckedModeBanner: false, // Supprime la bannière "Debug"
      initialRoute: '/', // Route initiale
      routes: {
        '/': (context) => const DebutPage(), // Page principale
        '/connexion': (context) => const ConnexionPage(), // Page de connexion
        '/createAccount': (context) => const CreateAccountPage(), // Page de création de compte
        '/homepage': (context) => const HomePage(), // Assurez-vous que HomePage existe
        '/user_profile_page': (context) => const UserProfilePage(),
        '/Pages/lobby_screen': (context) => const LobbyScreen(),
        '/friends': (context) => const FriendsPage(),
        '/addFriend': (context) => const AddFriendsPage(),
        '/editProfile': (context) => const EditProfilePage(),
        '/teamGenerator': (context) => const TeamGeneratorPage(),
        '/select_game': (context) => const SelectGamePage(), // La page SelectGame
        '/killer': (context) => const KillerPage(),
        '/killerActions': (context) => KillerActionsPage(
              players: ModalRoute.of(context)!.settings.arguments as List<String>,
            ),
        '/killerSummary': (context) {
          final playerData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return KillerSummaryPage(playerData: playerData);
        },
      },
    );
  }
}
