import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/app_theme.dart';
import '../home_page.dart'; // Assurez-vous que le chemin est correct

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  /// 🔹 **Connexion avec Email et Mot de passe**
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null && !user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez vérifier votre adresse email avant de vous connecter.")),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connexion réussie !")),
      );

      // Redirection vers la HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = "Utilisateur introuvable.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Mot de passe incorrect.";
      } else {
        errorMessage = "Erreur : ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  /// 🔹 **Connexion avec Google**
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // L'utilisateur a annulé

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de la connexion avec Google.")),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // 🔹 Récupération de l'email et extraction de l'identifiant avant le "@"
        String email = user.email ?? "";
        String baseName = email.split("@").first; 

        // 🔹 Génération d'un pseudo unique en comptant les utilisateurs existants
        final usersCollection = FirebaseFirestore.instance.collection('users');
        final QuerySnapshot existingUsers = await usersCollection.get();
        String uniquePseudo = "noob${existingUsers.docs.length + 1}";

        // 🔹 Enregistrement du nouvel utilisateur dans Firestore
        await usersCollection.doc(user.uid).set({
          'email': email,
          'pseudo': uniquePseudo, // Pseudo unique généré
          'name': baseName, // Identifiant email comme nom
          'surname': baseName, // Identifiant email comme prénom
          'photoUrl': user.photoURL ?? '',
          'gender': 'Autre',
          'createdAt': Timestamp.now(),
          'friends': [],
          'pending_approval': [],
          'friend_requests': [],
          'notifications': {
            'enabled': true,
            'friend_requests': true,
            'shifushot_requests': true,
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bienvenue, $uniquePseudo !")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connexion réussie, bienvenue ${userDoc['pseudo']} !")),
        );
      }

      // 🔹 Redirection vers la page d'accueil après l'authentification réussie
      Navigator.pushNamed(context, '/homepage');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion avec Google : $error")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 **Logo et Titre**
                  Center(
                    child: Column(
                      children: [
                        Text('SHIFUSHOT', style: theme.titleLarge.copyWith(fontSize: 36)),
                        const SizedBox(height: 50),
                        Text('Se connecter', style: theme.titleMedium.copyWith(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text('Remplissez les informations demandées ci-dessous', style: theme.bodyMedium, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  /// 🔹 **Champ Email**
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: theme.bodyMedium,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Veuillez entrer un email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Veuillez entrer un email valide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  /// 🔹 **Champ Mot de passe**
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: theme.bodyMedium,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
                      if (value.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 50),

                  /// 🔹 **Bouton Connexion**
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("C'est moi !", style: theme.buttonText),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// 🔹 **Bouton Connexion avec Google**
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      icon: Image.network(
                        'https://img.icons8.com/color/48/000000/google-logo.png',
                        width: 24,
                        height: 24,
                      ),
                      label: Text('Se connecter avec Google', style: theme.bodyMedium.copyWith(color: theme.textPrimary)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// 🔹 **Image en bas de la page**
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 200,
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
