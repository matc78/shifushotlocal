import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/routes.dart';

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
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;

      if (cred.user != null && !cred.user!.emailVerified) {
        _snack('Vérifie ton adresse email avant de te connecter.');
        return;
      }
      _snack('Connexion réussie !');
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
    } on FirebaseAuthException catch (e) {
      _snack(switch (e.code) {
        'user-not-found' => 'Utilisateur introuvable.',
        'wrong-password' => 'Mot de passe incorrect.',
        _ => 'Erreur : ${e.message}',
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) {
        _snack('Échec de la connexion avec Google.');
        return;
      }

      final users = FirebaseFirestore.instance.collection('users');
      final userDoc = await users.doc(user.uid).get();

      if (!userDoc.exists) {
        final baseName = (user.email ?? '').split('@').first;
        final existing = await users.get();
        final pseudo = 'noob${existing.docs.length + 1}';
        await users.doc(user.uid).set({
          'email': user.email ?? '',
          'pseudo': pseudo,
          'name': baseName,
          'surname': baseName,
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
          },
        });
        _snack('Bienvenue, $pseudo !');
      } else {
        _snack('Bienvenue ${userDoc['pseudo']} !');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
    } catch (error) {
      _snack('Erreur Google : $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      body: PartyBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: theme.textPrimary),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CONNEXION',
                    textAlign: TextAlign.center,
                    style: theme.overline.copyWith(color: theme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (rect) =>
                        theme.brandGradient.createShader(rect),
                    child: Text(
                      'SHIFUSHOT',
                      textAlign: TextAlign.center,
                      style: theme.displayLarge
                          .copyWith(color: Colors.white, fontSize: 44),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ton compte, tes potes, tes parties.',
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: theme.bodyLarge,
                    decoration: const InputDecoration(hintText: 'Email'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Entre un email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: theme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Mot de passe',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: theme.textMuted,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Entre un mot de passe';
                      if (v.length < 8) return 'Au moins 8 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: _loading ? 'Connexion…' : 'Connexion',
                    icon: Icons.login_rounded,
                    onPressed: _loading ? null : _signIn,
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: 'Continuer avec Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: _loading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, Routes.createAccount),
                    child: Text(
                      "Pas de compte ? Crées-en un",
                      style: theme.bodyMedium.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
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
