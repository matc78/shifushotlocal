import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import 'dart:math';
import '../../theme/app_theme.dart';

class CardDrawerPage extends StatefulWidget {
  const CardDrawerPage({Key? key}) : super(key: key);

  @override
  _CardDrawerPageState createState() => _CardDrawerPageState();
}

class _CardDrawerPageState extends State<CardDrawerPage> {
  final Random _random = Random();
  bool includeJokers = false;
  int numberOfCards = 1;
  List<PlayingCard> drawnCards = [];

  @override
  void initState() {
    super.initState();
    _drawCards();
  }

  void _drawCards() {
    setState(() {
      drawnCards = _generateRandomCards(numberOfCards, includeJokers);
    });
  }

  List<PlayingCard> _generateRandomCards(int count, bool includeJokers) {
    List<PlayingCard> deck = _createDeck(includeJokers);
    deck.shuffle(_random);
    return deck.take(count).toList();
  }

  List<PlayingCard> _createDeck(bool includeJokers) {
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

    if (includeJokers) {
      deck.add(PlayingCard(Suit.joker, CardValue.joker_1));
      deck.add(PlayingCard(Suit.joker, CardValue.joker_2));
    }

    return deck;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Tireur de cartes", style: theme.titleMedium),
        centerTitle: true,
        backgroundColor: theme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Number of cards selection
            Text("Nombre de cartes à tirer :", style: theme.bodyMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(4, (index) {
                return ChoiceChip(
                  label: Text("${index + 1}"),
                  selected: numberOfCards == index + 1,
                  selectedColor: theme.secondary,
                  backgroundColor: Colors.grey[300],
                  labelStyle: TextStyle(
                    color: numberOfCards == index + 1 ? Colors.white : theme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() {
                      numberOfCards = index + 1;
                    });
                    _drawCards();
                  },
                );
              }),
            ),
            const SizedBox(height: 20),

            // Include Jokers toggle
            SwitchListTile(
              title: Text("Inclure les Jokers", style: theme.bodyMedium),
              value: includeJokers,
              activeColor: theme.secondary,
              onChanged: (bool value) {
                setState(() {
                  includeJokers = value;
                });
                _drawCards();
              },
            ),
            const SizedBox(height: 20),

            // Display drawn cards
            SizedBox(
              height: 350, // Ajustement pour plus d'espace
              child: drawnCards.isEmpty
                  ? Text("Aucune carte tirée", style: theme.bodyLarge)
                  : numberOfCards == 4
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: drawnCards.sublist(0, 2).map((card) {
                                return _buildPlayingCard(card);
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: drawnCards.sublist(2, 4).map((card) {
                                return _buildPlayingCard(card);
                              }).toList(),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: drawnCards.map((card) {
                            return _buildPlayingCard(card);
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 70),

            // Draw new cards button
            ElevatedButton(
              onPressed: _drawCards,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text("Tirer de nouvelles cartes", style: theme.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher les cartes avec une taille plus grande
  Widget _buildPlayingCard(PlayingCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: 100, // Agrandissement des cartes
        height: 140, // Agrandissement des cartes
        child: PlayingCardView(card: card),
      ),
    );
  }
}
