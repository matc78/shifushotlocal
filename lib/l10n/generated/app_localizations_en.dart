// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shifushot';

  @override
  String get tagline => 'The #1 party game\nwith your crew.';

  @override
  String get partyOn => 'PARTY ON.';

  @override
  String get welcomeTo => 'WELCOME TO';

  @override
  String get home => 'HOME';

  @override
  String get ctaStart => 'Let\'s go!';

  @override
  String get ctaPlayAsGuest => 'Play as guest';

  @override
  String get ctaLaunchGame => 'Start a round';

  @override
  String get ctaSignIn => 'Sign in';

  @override
  String get ctaCreateAccount => 'Create account';

  @override
  String get ctaContinueWithGoogle => 'Continue with Google';

  @override
  String get ctaAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get ctaNoAccount => 'No account? Create one';

  @override
  String get guestModeBanner => 'Guest mode — local games only';

  @override
  String get guestModeFootnote =>
      'Guest mode: local games only.\nCreate an account for friends & online play.';

  @override
  String get selectGameTitle => 'Pick a game';

  @override
  String get sectionLocal => 'LOCAL';

  @override
  String get sectionOnline => 'ONLINE';

  @override
  String get sectionFeatures => 'TOOLS & FUN';

  @override
  String get accountRequired => 'Account required';

  @override
  String get errEmailRequired => 'Enter an email';

  @override
  String get errEmailInvalid => 'Invalid email';

  @override
  String get errPasswordRequired => 'Enter a password';

  @override
  String get errPasswordTooShort => 'At least 8 characters';

  @override
  String get errPasswordWeak =>
      'Password: 8+ chars, 1 uppercase, 1 digit, 1 special.';

  @override
  String get errPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get errPseudoTaken => 'Username already taken.';

  @override
  String get errEmailNotVerified => 'Verify your email before signing in.';

  @override
  String get okAccountCreated =>
      'Account created! A verification email has been sent.';

  @override
  String get okWelcome => 'Welcome!';

  @override
  String okWelcomeNamed(String pseudo) {
    return 'Welcome $pseudo!';
  }
}
