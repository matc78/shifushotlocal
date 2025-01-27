import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/create_account_page.dart';
import 'package:shifushotlocal/debut_page.dart';
import 'package:shifushotlocal/connexion_page.dart'; // Importez la page de connexion
import 'package:shifushotlocal/friends_page.dart';
import 'package:shifushotlocal/home_page.dart';
import 'package:shifushotlocal/user_profil_page.dart';
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
        '/friends': (context) => const FriendsPage(),

      },
    );
  }
}
