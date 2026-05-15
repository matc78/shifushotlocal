import 'dart:math';

import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class PyramidCardPage extends StatefulWidget {
  const PyramidCardPage({super.key});

  @override
  State<PyramidCardPage> createState() => _PyramidCardPageState();
}

class _PyramidCardPageState extends State<PyramidCardPage> {
  final Random _random = Random();
  late List<PlayingCard> _cards;
  late List<bool> _flipped;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    _initCards();
  }

  void _initCards() {
    setState(() {
      _cards = _generate(4);
      _flipped = List.generate(4, (_) => false);
    });
  }

  List<PlayingCard> _generate(int count) {
    final deck = <PlayingCard>[];
    for (final suit in Suit.values) {
      if (suit == Suit.joker) continue;
      for (final value in CardValue.values) {
        if (value == CardValue.joker_1 || value == CardValue.joker_2) continue;
        deck.add(PlayingCard(suit, value));
      }
    }
    deck.shuffle(_random);
    return deck.take(count).toList();
  }

  void _flip(int index) {
    if (_isFlipping) return;
    setState(() {
      _isFlipping = true;
      _flipped[index] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _flipped[index] = false;
        _isFlipping = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = MediaQuery.of(context).size.width * 0.52;
    final cardHeight = cardWidth * 0.7;

    // Background flips brand-red while a card is revealed (drinking signal)
    // and stays on the dark base otherwise.
    final scaffoldBg = _isFlipping ? theme.primary : Colors.transparent;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: AppShell(
        title: 'Cartes pour pyramide',
        child: Stack(
          children: List.generate(4, (index) {
            final spacing = cardHeight * 0.15;
            final startPosition =
                (screenHeight - (4 * cardHeight + 3 * spacing)) / 5;
            return Positioned(
              top: startPosition + index * (cardHeight + spacing),
              left: (MediaQuery.of(context).size.width - cardWidth) / 2,
              child: GestureDetector(
                onTap: () => _flip(index),
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: PlayingCardView(
                      card: _cards[index],
                      showBack: !_flipped[index],
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
