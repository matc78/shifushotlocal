import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _pseudoController = TextEditingController();
  String? _selectedGender;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final email = _emailController.text.trim();
    final pseudo = _pseudoController.text.trim();

    // Validation du mot de passe : au moins 8 caractères, 1 majuscule, 1 chiffre, 1 caractère spécial
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?/~\\-])[A-Za-z\d!@#$%^&*()_+{}\[\]:;<>,.?/~\\-]{8,}$');

    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le mot de passe doit contenir au moins 8 caractères, une majuscule, un chiffre et un caractère spécial."),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas.")),
      );
      return;
    }

    try {
      // Vérification si le pseudo est unique
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('pseudo', isEqualTo: pseudo)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le pseudo est déjà utilisé.")),
        );
        return;
      }

      // Création du compte avec Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Envoi de l'email de vérification
      await userCredential.user?.sendEmailVerification();

      // Sauvegarde des informations de l'utilisateur dans Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'pseudo': pseudo,
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'gender': _selectedGender,
        'createdAt': Timestamp.now(),
        'emailVerified': false, // Ajout d'un champ pour suivre la vérification de l'email
        'friends': [],
        'pending_approval': [],
        'friend_requests': [],
        'photoUrl': 'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé avec succès ! Un email de vérification a été envoyé.")),
      );

      // Redirection vers la page de connexion après création du compte
      Navigator.pushNamed(context, '/connexion');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = "Cet email est déjà utilisé.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Le mot de passe est trop faible.";
      } else {
        errorMessage = "Erreur : ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Une erreur s'est produite : $e")),
      );
    }
  }


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
          onPressed: () {
            Navigator.pop(context);
          },
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
                  Center(
                    child: Text(
                      'SHIFUSHOT',
                      style: theme.titleLarge.copyWith(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Créer un compte',
                    style: theme.titleMedium.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
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
                    label: Text(
                      'Se connecter avec Google',
                      style: theme.bodyMedium.copyWith(color: theme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'OU',
                    style: theme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Remplissez les informations demandées ci-dessous.',
                    style: theme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un email.';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Veuillez entrer un email valide.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre prénom.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pseudoController,
                    decoration: InputDecoration(
                      labelText: 'Pseudo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un pseudo.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Genre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    items: ['Homme', 'Femme', 'Autre']
                        .map((gender) => DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            ))
                        .toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un genre.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe.';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, // Largeur maximale pour le bouton
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        child: Text(
                          'Créer un compte',
                          style: theme.buttonText.copyWith(color: theme.background),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24), // Espacement sous le bouton

                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Naviguer vers la page de connexion
                        Navigator.pushNamed(context, '/connexion');
                      },
                      child: Text(
                        "Déjà un compte ? Connecte-toi ici !",
                        style: theme.bodyMedium.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
