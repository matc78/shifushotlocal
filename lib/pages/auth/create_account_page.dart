import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

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
  bool _loading = false;

  static final _passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?/~\\-])[A-Za-z\d!@#$%^&*()_+{}\[\]:;<>,.?/~\\-]{8,}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    final email = _emailController.text.trim();
    final pseudo = _pseudoController.text.trim();

    if (!_passwordRegex.hasMatch(password)) {
      _snack(
          'Mot de passe : 8 caractères min, 1 majuscule, 1 chiffre, 1 spécial.');
      return;
    }
    if (password != confirm) {
      _snack('Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _loading = true);
    try {
      final users = FirebaseFirestore.instance.collection('users');
      final taken =
          await users.where('pseudo', isEqualTo: pseudo).limit(1).get();
      if (taken.docs.isNotEmpty) {
        _snack('Pseudo déjà utilisé.');
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.sendEmailVerification();
      final user = cred.user;
      if (user == null) {
        _snack('Erreur : utilisateur non authentifié.');
        return;
      }

      await users.doc(user.uid).set({
        'email': email,
        'pseudo': pseudo,
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'gender': _selectedGender,
        'createdAt': Timestamp.now(),
        'emailVerified': false,
        'friends': [],
        'pending_approval': [],
        'friend_requests': [],
        'photoUrl':
            'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
        'notifications': {
          'enabled': true,
          'friend_requests': true,
          'shifushot_requests': true,
        },
      });

      _snack('Compte créé ! Un email de vérification a été envoyé.');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/connexion');
    } on FirebaseAuthException catch (e) {
      _snack(switch (e.code) {
        'email-already-in-use' => 'Cet email est déjà utilisé.',
        'weak-password' => 'Mot de passe trop faible.',
        _ => 'Erreur : ${e.message}',
      });
    } catch (e) {
      _snack("Erreur : $e");
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
      Navigator.pushNamedAndRemoveUntil(context, '/homepage', (_) => false);
    } catch (e) {
      _snack('Erreur Google : $e');
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
                  const SizedBox(height: 16),
                  Text(
                    'NOUVEAU JOUEUR',
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
                          .copyWith(color: Colors.white, fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GhostButton(
                    label: 'Continuer avec Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: _loading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OU', style: theme.overline),
                      ),
                      Expanded(child: Divider(color: theme.border)),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: theme.bodyLarge,
                          decoration: const InputDecoration(hintText: 'Nom'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp('[a-zA-Z]')),
                          ],
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _surnameController,
                          style: theme.bodyLarge,
                          decoration: const InputDecoration(hintText: 'Prénom'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp('[a-zA-Z]')),
                          ],
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pseudoController,
                    style: theme.bodyLarge,
                    decoration: const InputDecoration(hintText: 'Pseudo'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Entre un pseudo' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(hintText: 'Genre'),
                    style: theme.bodyLarge,
                    dropdownColor: theme.surface,
                    initialValue: _selectedGender,
                    onChanged: (v) => setState(() => _selectedGender = v),
                    items: const ['Homme', 'Femme', 'Autre']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    validator: (v) => v == null ? 'Sélectionne un genre' : null,
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    style: theme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Confirme le mot de passe',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: theme.textMuted,
                        ),
                        onPressed: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Confirme le mot de passe' : null,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: _loading ? 'Création…' : 'Créer mon compte',
                    icon: Icons.person_add_alt_rounded,
                    onPressed: _loading ? null : _createAccount,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/connexion'),
                    child: Text(
                      'Déjà un compte ? Connecte-toi',
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
