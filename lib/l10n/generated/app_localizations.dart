import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// App name shown in OS task switcher
  ///
  /// In fr, this message translates to:
  /// **'Shifushot'**
  String get appTitle;

  /// Subtitle under the SHIFUSHOT wordmark on the welcome screen
  ///
  /// In fr, this message translates to:
  /// **'Le party game N°1\nentre potes.'**
  String get tagline;

  /// No description provided for @partyOn.
  ///
  /// In fr, this message translates to:
  /// **'PARTY ON.'**
  String get partyOn;

  /// No description provided for @welcomeTo.
  ///
  /// In fr, this message translates to:
  /// **'WELCOME TO'**
  String get welcomeTo;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'HOME'**
  String get home;

  /// No description provided for @ctaStart.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti !'**
  String get ctaStart;

  /// No description provided for @ctaPlayAsGuest.
  ///
  /// In fr, this message translates to:
  /// **'Jouer sans compte'**
  String get ctaPlayAsGuest;

  /// No description provided for @ctaLaunchGame.
  ///
  /// In fr, this message translates to:
  /// **'Lancer une partie'**
  String get ctaLaunchGame;

  /// No description provided for @ctaSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get ctaSignIn;

  /// No description provided for @ctaCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get ctaCreateAccount;

  /// No description provided for @ctaContinueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get ctaContinueWithGoogle;

  /// No description provided for @ctaAlreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Connecte-toi'**
  String get ctaAlreadyHaveAccount;

  /// No description provided for @ctaNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ? Crées-en un'**
  String get ctaNoAccount;

  /// No description provided for @guestModeBanner.
  ///
  /// In fr, this message translates to:
  /// **'Mode invité — jeux locaux uniquement'**
  String get guestModeBanner;

  /// No description provided for @guestModeFootnote.
  ///
  /// In fr, this message translates to:
  /// **'En invité : jeux locaux uniquement.\nCrée un compte pour les amis & le jeu en ligne.'**
  String get guestModeFootnote;

  /// No description provided for @selectGameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton jeu'**
  String get selectGameTitle;

  /// No description provided for @sectionLocal.
  ///
  /// In fr, this message translates to:
  /// **'EN LOCAL'**
  String get sectionLocal;

  /// No description provided for @sectionOnline.
  ///
  /// In fr, this message translates to:
  /// **'EN LIGNE'**
  String get sectionOnline;

  /// No description provided for @sectionFeatures.
  ///
  /// In fr, this message translates to:
  /// **'OUTILS & FUN'**
  String get sectionFeatures;

  /// No description provided for @accountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Compte requis'**
  String get accountRequired;

  /// No description provided for @errEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entre un email'**
  String get errEmailRequired;

  /// No description provided for @errEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get errEmailInvalid;

  /// No description provided for @errPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entre un mot de passe'**
  String get errPasswordRequired;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get errPasswordTooShort;

  /// No description provided for @errPasswordWeak.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe : 8 caractères min, 1 majuscule, 1 chiffre, 1 spécial.'**
  String get errPasswordWeak;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get errPasswordMismatch;

  /// No description provided for @errPseudoTaken.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo déjà utilisé.'**
  String get errPseudoTaken;

  /// No description provided for @errEmailNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ton adresse email avant de te connecter.'**
  String get errEmailNotVerified;

  /// No description provided for @okAccountCreated.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé ! Un email de vérification a été envoyé.'**
  String get okAccountCreated;

  /// No description provided for @okWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get okWelcome;

  /// No description provided for @okWelcomeNamed.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue {pseudo} !'**
  String okWelcomeNamed(String pseudo);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
