import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Shifushot Local")),
        body: Center(child: Text("Firebase Initialized!")),
      ),
    );
  }
}
