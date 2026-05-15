import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/services/auth_service.dart';
import 'package:shifushotlocal/services/user_repository.dart';
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

  AuthService get _auth => AuthServiceLocator.instance;
  UserRepository get _users => UserRepositoryLocator.instance;

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

    if (await _users.isPseudoTaken(pseudo)) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Pseudo déjà utilisé.');
      return;
    }

    final result = await _auth.createAccountWithEmail(
      email: _emailController.text.trim(),
      password: password,
      pseudo: pseudo,
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      gender: _selectedGender,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case AuthSuccess():
        _snack('Compte créé ! Un email de vérification a été envoyé.');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.connexion);
      case AuthFailure(:final message):
        _snack(message);
      case AuthEmailNotVerified():
      case AuthCancelled():
        break;
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final result = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case AuthSuccess(:final isNewUser):
        _snack(isNewUser ? 'Bienvenue !' : 'Connexion réussie !');
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
      case AuthFailure(:final message):
        _snack(message);
      case AuthEmailNotVerified():
      case AuthCancelled():
        break;
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
                      if (v == null || v.isEmpty) {
                        return 'Entre un mot de passe';
                      }
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
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Confirme le mot de passe'
                        : null,
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
                        context, Routes.connexion),
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
