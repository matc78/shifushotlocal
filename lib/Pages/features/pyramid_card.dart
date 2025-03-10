import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import 'dart:math';
import '../../theme/app_theme.dart';

class PyramidCardPage extends StatefulWidget {
  const PyramidCardPage({super.key});

  @override
  _PyramidCardPageState createState() => _PyramidCardPageState();
}

class _PyramidCardPageState extends State<PyramidCardPage> {
  final Random _random = Random();
  late List<PlayingCard> cards;
  late List<bool> cardFlipped; // Suivi des cartes retournées
  bool isCardFlipping = false; // Bloque les actions pendant la rotation

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  /// 🔹 Initialise 4 cartes aléatoires
  void _initializeCards() {
    setState(() {
      cards = _generateRandomCards(4);
      cardFlipped = List.generate(4, (_) => false);
    });
  }

  /// 🔹 Génère un jeu de cartes mélangé et en prend 4
  List<PlayingCard> _generateRandomCards(int count) {
    List<PlayingCard> deck = _createDeck();
    deck.shuffle(_random);
    return deck.take(count).toList();
  }

  /// 🔹 Crée un deck de cartes sans joker
  List<PlayingCard> _createDeck() {
    List<PlayingCard> deck = [];

    for (var suit in Suit.values) {
      if (suit != Suit.joker) {
        for (var value in CardValue.values) {
          if (value != CardValue.joker_1 && value != CardValue.joker_2) {
            deck.add(PlayingCard(suit, value));
          }
        }
      }
    }
    return deck;
  }

  /// 🔹 Retourne la carte pendant 2 secondes
  void _flipCard(int index) {
    if (isCardFlipping) return; // Empêche d'autres interactions

    setState(() {
      isCardFlipping = true;
      cardFlipped[index] = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        cardFlipped[index] = false;
        isCardFlipping = false;
      });
    });
  }

  @override
Widget build(BuildContext context) {
  final theme = AppTheme.of(context);
  double screenHeight = MediaQuery.of(context).size.height;
  double cardWidth = MediaQuery.of(context).size.width * 0.52; // Ajuster la largeur
  double cardHeight = cardWidth * 0.7; // Garder le ratio des cartes

  return Scaffold(
    backgroundColor: isCardFlipping ? Colors.redAccent : Colors.lightGreenAccent,
    appBar: AppBar(
      title: Text("Cartes pour pyramide", style: theme.titleMedium),
      centerTitle: true,
      backgroundColor: isCardFlipping ? Colors.redAccent : Colors.lightGreenAccent,
      elevation: 0,
      iconTheme: IconThemeData(color: theme.textPrimary),
    ),
    body: Center(
      child: Stack(
        children: List.generate(4, (index) {
          double spacing = cardHeight * 0.15; // Espacement fixe entre les cartes
          double startPosition = (screenHeight - (4 * cardHeight + 3 * spacing)) /4; // Centrage vertical
          if (kDebugMode) {
            print("start position : $startPosition");
          }

          return Positioned(
            top: startPosition + index * (cardHeight + spacing), // Positionner chaque carte
            left: (MediaQuery.of(context).size.width - cardWidth) / 2, // Centrage horizontal
            child: GestureDetector(
              onTap: () => _flipCard(index),
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: RotatedBox(
                  quarterTurns: 1, // Rotation de 90° pour afficher horizontalement
                  child: PlayingCardView(
                    card: cards[index],
                    showBack: !cardFlipped[index],
                    elevation: 3.0,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}
}
