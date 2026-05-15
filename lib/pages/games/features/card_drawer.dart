import 'dart:math';

import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class CardDrawerPage extends StatefulWidget {
  const CardDrawerPage({super.key});

  @override
  State<CardDrawerPage> createState() => _CardDrawerPageState();
}

class _CardDrawerPageState extends State<CardDrawerPage> {
  final Random _random = Random();
  bool _includeJokers = false;
  int _numberOfCards = 1;
  List<PlayingCard> _drawn = [];

  @override
  void initState() {
    super.initState();
    _draw();
  }

  void _draw() {
    setState(() => _drawn = _generate(_numberOfCards, _includeJokers));
  }

  List<PlayingCard> _generate(int count, bool jokers) {
    final deck = <PlayingCard>[];
    for (final suit in Suit.values) {
      if (suit == Suit.joker) continue;
      for (final value in CardValue.values) {
        if (value == CardValue.joker_1 || value == CardValue.joker_2) continue;
        deck.add(PlayingCard(suit, value));
      }
    }
    if (jokers) {
      deck.add(PlayingCard(Suit.joker, CardValue.joker_1));
      deck.add(PlayingCard(Suit.joker, CardValue.joker_2));
    }
    deck.shuffle(_random);
    return deck.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: 'Tireur de cartes',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('NOMBRE DE CARTES',
                style: theme.overline
                    .copyWith(color: theme.textMuted, letterSpacing: 2)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) {
                final n = i + 1;
                final selected = _numberOfCards == n;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _numberOfCards = n);
                        _draw();
                      },
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: selected ? theme.brandGradient : null,
                          color: selected ? null : theme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                              color: selected ? theme.primary : theme.border),
                        ),
                        child: Text('$n',
                            style: theme.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SwitchListTile(
                title: Text('Inclure les Jokers', style: theme.bodyLarge),
                value: _includeJokers,
                activeThumbColor: theme.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) {
                  setState(() => _includeJokers = v);
                  _draw();
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: _drawn.isEmpty
                    ? Text('Aucune carte tirée', style: theme.bodyLarge)
                    : _numberOfCards == 4
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _drawn
                                    .sublist(0, 2)
                                    .map(_buildCard)
                                    .toList(),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _drawn
                                    .sublist(2, 4)
                                    .map(_buildCard)
                                    .toList(),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _drawn.map(_buildCard).toList(),
                          ),
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Tirer de nouvelles cartes',
              icon: Icons.refresh_rounded,
              onPressed: _draw,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PlayingCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 90,
        height: 130,
        child: PlayingCardView(card: card),
      ),
    );
  }
}
