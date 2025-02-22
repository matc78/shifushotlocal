# **Shifushotlocal**

## 📌 **Description du projet**
Shifushotlocal est une application mobile développée avec Flutter visant à proposer une expérience ludique et interactive autour de jeux de soirée. Elle permet aux utilisateurs de créer des parties, d'inviter des amis et d'accéder à une variété de mini-jeux en ligne et hors ligne.

## ⚙ **Environnement technique**
- **Langage de programmation :** Dart (Flutter)
- **Version de Flutter SDK :** 3.5.4
- **Outil de build :** Gradle 8.0
- **Version de Java :** 17
- **IDE utilisé :** Android Studio (pour l’émulation et les tests)

## 📦 **Dépendances**
### **Dépendances principales :**
- `cloud_firestore: ^5.6.2` → Base de données Firestore pour stocker les données des parties et des utilisateurs.
- `firebase_auth: ^5.4.1` → Gestion de l’authentification utilisateur via Firebase.
- `firebase_core: ^3.10.1` → Outils Firebase nécessaires au bon fonctionnement de l’application.
- `firebase_storage: ^12.4.1` → Stockage d’images et autres fichiers sur Firebase Storage.
- `google_sign_in: ^6.2.2` → Connexion via Google.
- `intl: ^0.20.2` → Gestion des formats de date et de texte multilingues.
- `uuid: ^4.5.1` → Génération d’identifiants uniques pour les parties et utilisateurs.
- `flutter_launcher_icons: ^0.14.3` → Personnalisation des icônes de l’application.

### **Dépendances UI et graphiques :**
- `dice_icons: ^0.1.7` → Icônes de dés pour certains jeux.
- `font_awesome_flutter: ^10.8.0` → Icônes supplémentaires pour l’interface.
- `playing_cards: ^0.4.1+11` → Gestion des jeux de cartes.
- `playing_cards_layouts: ^1.0.1` → Mises en page spécifiques aux jeux de cartes.

### **Dépendances de développement et tests :**
- `flutter_lints: ^4.0.0` → Bonnes pratiques et vérification du code.
- `flutter_test:` → Outils de tests unitaires intégrés à Flutter.

## 📁 **Structure du projet**
L’arborescence du projet est organisée pour séparer les différentes fonctionnalités :

```
lib/
│── Pages/
│   ├── connexion/
│   │   ├── connexion_page.dart
│   │   ├── create_account_page.dart
│   │   ├── debut_page.dart
│   │   ├── select_connect_page.dart
│   ├── features/
│   │   ├── card_drawer.dart
│   │   ├── team_generator_page.dart
│   ├── feedback/
│   │   ├── feedback_page.dart
│   ├── friends/
│   │   ├── add_friends_page.dart
│   │   ├── friends_page.dart
│   ├── local_games/
│   │   ├── bizkit/
│   │   ├── clicker/
│   │   ├── horloge/
│   │   ├── killer/
│   │   ├── paper/
│── online_games/
│   ├── lobby_screen_online.dart
│   ├── lobby_waiting_screen.dart
│── profil/
│   ├── edit_profil_page.dart
│   ├── user_profil_page.dart
│── theme/
│   ├── app_theme.dart
│── main.dart
│── firebase_options.dart
```

## 🚀 **Installation et exécution**
### **Pré-requis**
- Installer **Flutter SDK 3.5.4** : [Documentation officielle](https://flutter.dev/docs/get-started/install)
- Installer **Android Studio** (pour l’émulation et le build)
- Avoir un compte Firebase configuré

### **Étapes d’installation**
1. **Cloner le projet** :
   ```sh
   git clone <repository-url>
   cd shifushotlocal
   ```

2. **Installer les dépendances** :
   ```sh
   flutter pub get
   ```

3. **Configurer Firebase** :
   - Ajouter le fichier `google-services.json` pour Android.
   - Ajouter `GoogleService-Info.plist` pour iOS.

4. **Lancer l’application** :
   ```sh
   flutter run
   ```

## 📜 **Gestion des assets**
Le projet inclut plusieurs assets :
- **Images** : Logos, icônes et éléments graphiques (stockés dans `assets/images/`).
- **Fichiers JSON** : Données préconfigurées pour certains jeux (`assets/jsons/`).
- **Fonts** : Polices personnalisées (déclarées dans `pubspec.yaml`).

## 🔥 **Bonnes pratiques**
- Suivre les conventions de Flutter/Dart pour le nommage et l’organisation du code.
- Éviter de stocker des informations sensibles dans le code source.
- Utiliser `flutter analyze` et `flutter test` pour s’assurer de la qualité du code.

---

Avec cette documentation, tout développeur reprenant le projet pourra rapidement comprendre son fonctionnement et l’installer correctement.
