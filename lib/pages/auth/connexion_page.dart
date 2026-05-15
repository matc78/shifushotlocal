import 'package:flutter/material.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/services/auth_service.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

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

  AuthService get _auth => AuthServiceLocator.instance;

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

  Future<void> _handle(AuthResult result, {String? newUserMessage}) async {
    if (!mounted) return;
    switch (result) {
      case AuthSuccess(:final isNewUser):
        if (isNewUser && newUserMessage != null) _snack(newUserMessage);
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
      case AuthEmailNotVerified():
        _snack('Vérifie ton adresse email avant de te connecter.');
      case AuthCancelled():
        break;
      case AuthFailure(:final message):
        _snack(message);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await _auth.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    await _handle(result);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final result = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    await _handle(result, newUserMessage: 'Bienvenue !');
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
                      if (v == null || v.isEmpty) {
                        return 'Entre un mot de passe';
                      }
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
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, Routes.createAccount),
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
