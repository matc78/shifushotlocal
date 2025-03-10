import 'dart:math';
import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import '../../../theme/app_theme.dart';

class ClockGameScreen extends StatefulWidget {
  const ClockGameScreen({super.key});

  @override
  State<ClockGameScreen> createState() => _ClockGameScreenState();
}

class _ClockGameScreenState extends State<ClockGameScreen> {
  List<PlayingCard> deck = [];
  Map<int, bool> revealedCards = {};
  Random random = Random();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  List<String> players = [];
  List<String> remainingGames = [];
  int currentPlayerIndex = 0;
  int gorgees = 0;
  int shots = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    players = args['players'] ?? [];
    remainingGames = args['remainingGames'] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _initializeDeck();
    _initializeRevealedCards();
  }

  void _initializeDeck() {
    deck = [];
    for (Suit suit in Suit.values.where((suit) => suit != Suit.joker)) {
      for (CardValue value in CardValue.values) {
        deck.add(PlayingCard(suit, value));
      }
    }
    deck.shuffle(random);
  }

  void _initializeRevealedCards() {
    revealedCards = {for (int i = 0; i < 9; i++) i: false};
  }

  void _resetCards() {
    setState(() {
      deck.shuffle(random); // Mélange à nouveau le deck
      _initializeRevealedCards(); // Remet toutes les cartes en état caché
    });
  }

  void _onCardSelected(int index) async {
    if (revealedCards[index]!) return; // Si la carte est déjà visible, ignorer l'action

    final colorChoice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choisissez une couleur"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop("Rouge"),
              child: const Text("Rouge"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop("Noir"),
              child: const Text("Noir"),
            ),
          ],
        ),
      ),
    );

    if (colorChoice != null) {
      final selectedCard = deck[index];
      final isRed = selectedCard.suit == Suit.hearts || selectedCard.suit == Suit.diamonds;

      setState(() {
        revealedCards[index] = true; // Marquer la carte comme visible
      });

      int gorgeesPariees = 0;
      int shotsParies = 0;

      if (index == 0) {
        shotsParies = 2; // Carte centrale
      } else if ([1, 2, 3, 4].contains(index)) {
        gorgeesPariees = 3; // Cartes éloignées
      } else {
        gorgeesPariees = 5; // Cartes proches du centre 
      }

      if ((isRed && colorChoice == "Rouge") || (!isRed && colorChoice == "Noir")) {
        // En cas de victoire
        setState(() {
          gorgees += gorgeesPariees;
          shots += shotsParies;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vous avez gagné !"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // En cas de défaite : ajouter la pénalité au compteur
        final totalGorgees = gorgees + gorgeesPariees;
        final totalShots = shots + shotsParies;

        await showDialog(
          context: context,
          builder: (context) => Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: Colors.white.withOpacity(0.85), // Fond semi-transparent
            ),
            child: AlertDialog(
              title: const Text("Tour terminé"),
              content: RichText(
                text: TextSpan(
                  style: const TextStyle( // Style de base pour éviter l’héritage non voulu
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: "${players[currentPlayerIndex]} doit prendre ",
                    ),
                    TextSpan(
                      text: "$totalGorgees ",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: "gorgée(s) ",
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                    const TextSpan(
                      text: "et ",
                    ),
                    TextSpan(
                      text: "$totalShots ",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: "shot(s).",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      gorgees = 0; // Réinitialiser le compteur en cas de défaite
                      shots = 0;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Continuer"),
                ),
              ],
            ),
          ),
        );
      }

      // Passer au joueur suivant après chaque action
      setState(() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      });

      // Si toutes les cartes sont visibles, réinitialiser
      if (revealedCards.values.every((visible) => visible)) {
        Future.delayed(const Duration(seconds: 1), () => _resetCards());
      }
    }
  }


  void _goToNextGame() {
    if (remainingGames.isNotEmpty) {
      Navigator.pushReplacementNamed(
        context,
        remainingGames.first,
        arguments: {
          'players': players,
          'remainingGames': remainingGames.sublist(1),
        },
      );
    } else {
      // Si plus de jeux restants, revenir à la page d'accueil
      Navigator.pushReplacementNamed(context, '/homepage');
    }
  }

  void _showRulesExplanation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Règles du jeu"),
        content: const Text(
          "Le joueur doit deviner la couleur de la carte avant de la retourner.\n\n"
          "- Carte centrale : 2 shots\n"
          "- Cartes proches du centre : 5 gorgées\n"
          "- Cartes éloignées : 3 gorgées\n\n"
          "Si le joueur devine juste, il ne boit rien. Sinon, il boit le nombre indiqué.\n"
          "Une fois toutes les cartes retournées, une nouvelle série de cartes apparaît.",
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Compris !"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double cardSize = screenWidth / 6;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "L'horloge",
            style: theme.titleMedium,
          ),
          centerTitle: true,
          backgroundColor: theme.background,
          iconTheme: IconThemeData(color: theme.textPrimary),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline, color: theme.primary),
              onPressed: _showRulesExplanation,
            ),
          ],
        ),
        backgroundColor: theme.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(1.7)
                  ..rotateZ(pi / 2)
                  ..translate(screenWidth * 0.02, screenWidth * 0.005),
                child: Image.asset(
                  "assets/images/tapis_de_jeu.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "C'est le tour de ${players[currentPlayerIndex]}",
                        style: theme.titleLarge,
                      ),
                      const SizedBox(height: 4), // Réduit l'espace entre les deux textes
                      Text(
                        "Compteur : $gorgees gorgée(s), $shots shot(s)",
                        style: theme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: screenWidth,
                      height: screenWidth * 1.5,
                      child: Stack(
                        children: [
                          Positioned(
                            left: screenWidth / 2 - cardSize / 2,
                            top: screenWidth * 0.7 - cardSize / 2,
                            child: buildCard(0, cardSize),
                          ),
                          Positioned(
                            left: screenWidth / 2 - cardSize / 2,
                            top: screenWidth * 0.07,
                            child: buildCard(1, cardSize),
                          ),
                          Positioned(
                            left: screenWidth / 2 - cardSize / 2,
                            top: screenWidth * 0.43 - cardSize / 2,
                            child: buildCard(5, cardSize),
                          ),
                          Positioned(
                            left: screenWidth / 2 - cardSize / 2,
                            top: screenWidth * 1.24 - cardSize / 2,
                            child: buildCard(2, cardSize),
                          ),
                          Positioned(
                            left: screenWidth / 2 - cardSize / 2,
                            top: screenWidth * 0.97 - cardSize / 2,
                            child: buildCard(8, cardSize),
                          ),
                          Positioned(
                            left: screenWidth * 0.03,
                            top: screenWidth * 0.7 - cardSize / 2,
                            child: buildCard(3, cardSize),
                          ),
                          Positioned(
                            left: screenWidth * 0.30 - cardSize / 2,
                            top: screenWidth * 0.7 - cardSize / 2,
                            child: buildCard(7, cardSize),
                          ),
                          Positioned(
                            left: screenWidth * 0.97 - cardSize,
                            top: screenWidth * 0.7 - cardSize / 2,
                            child: buildCard(4, cardSize),
                          ),
                          Positioned(
                            left: screenWidth * 0.70 - cardSize / 2,
                            top: screenWidth * 0.7 - cardSize / 2,
                            child: buildCard(6, cardSize),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _goToNextGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      minimumSize: const Size(150, 20), // Largeur maximale
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Fin du jeu",
                      style: theme.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard(int index, double size) {
    return GestureDetector(
      onTap: () => _onCardSelected(index),
      child: SizedBox(
        width: size,
        height: size * 1.5,
        child: PlayingCardView(
          card: deck[index],
          showBack: !revealedCards[index]!,
          elevation: 3.0,
        ),
      ),
    );
  }
}
