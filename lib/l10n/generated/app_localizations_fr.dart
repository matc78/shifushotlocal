// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Shifushot';

  @override
  String get tagline => 'Le party game N°1\nentre potes.';

  @override
  String get partyOn => 'PARTY ON.';

  @override
  String get welcomeTo => 'WELCOME TO';

  @override
  String get home => 'HOME';

  @override
  String get ctaStart => 'C\'est parti !';

  @override
  String get ctaPlayAsGuest => 'Jouer sans compte';

  @override
  String get ctaLaunchGame => 'Lancer une partie';

  @override
  String get ctaSignIn => 'Connexion';

  @override
  String get ctaCreateAccount => 'Créer un compte';

  @override
  String get ctaContinueWithGoogle => 'Continuer avec Google';

  @override
  String get ctaAlreadyHaveAccount => 'Déjà un compte ? Connecte-toi';

  @override
  String get ctaNoAccount => 'Pas de compte ? Crées-en un';

  @override
  String get guestModeBanner => 'Mode invité — jeux locaux uniquement';

  @override
  String get guestModeFootnote =>
      'En invité : jeux locaux uniquement.\nCrée un compte pour les amis & le jeu en ligne.';

  @override
  String get selectGameTitle => 'Choisis ton jeu';

  @override
  String get sectionLocal => 'EN LOCAL';

  @override
  String get sectionOnline => 'EN LIGNE';

  @override
  String get sectionFeatures => 'OUTILS & FUN';

  @override
  String get accountRequired => 'Compte requis';

  @override
  String get errEmailRequired => 'Entre un email';

  @override
  String get errEmailInvalid => 'Email invalide';

  @override
  String get errPasswordRequired => 'Entre un mot de passe';

  @override
  String get errPasswordTooShort => 'Au moins 8 caractères';

  @override
  String get errPasswordWeak =>
      'Mot de passe : 8 caractères min, 1 majuscule, 1 chiffre, 1 spécial.';

  @override
  String get errPasswordMismatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get errPseudoTaken => 'Pseudo déjà utilisé.';

  @override
  String get errEmailNotVerified =>
      'Vérifie ton adresse email avant de te connecter.';

  @override
  String get okAccountCreated =>
      'Compte créé ! Un email de vérification a été envoyé.';

  @override
  String get okWelcome => 'Bienvenue !';

  @override
  String okWelcomeNamed(String pseudo) {
    return 'Bienvenue $pseudo !';
  }
}
