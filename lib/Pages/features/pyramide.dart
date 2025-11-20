import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playing_cards/playing_cards.dart';

import '../../theme/app_theme.dart';

class PyramidePage extends StatefulWidget {
  const PyramidePage({super.key});

  @override
  State<PyramidePage> createState() => _PyramidePageState();
}

class _PyramidePageState extends State<PyramidePage> {
  static const int _rows = 6;
  static const int _challengeGreenCount = 7;
  static const int _challengeBlackCount = 2;
  final Random _random = Random();

  late final List<List<int>> _rowIndexMatrix = _buildRowIndices();
  late final List<int> _revealOrder = _buildRevealOrder();

  late List<PlayingCard> _cards;
  late List<bool> _flipped;
  late List<CardBadge> _badges;
  int _nextIndex = 0;
  Timer? _highlightTimer;
  PlayingCard? _highlightedCard;
  PlayingCard? _lastRevealedCard;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
    _resetGame();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    _highlightTimer?.cancel();
    super.dispose();
  }

  int get _totalCards => (_rows * (_rows + 1)) ~/ 2;

  List<List<int>> _buildRowIndices() {
    final rows = <List<int>>[];
    var current = 0;
    for (int row = 0; row < _rows; row++) {
      final rowLength = row + 1;
      rows.add(List<int>.generate(rowLength, (_) => current++));
    }
    return rows;
  }

  List<int> _buildRevealOrder() {
    final order = <int>[];
    for (int row = _rows - 1; row >= 0; row--) {
      order.addAll(_rowIndexMatrix[row]);
    }
    return order;
  }

  void _resetGame() {
    final deck = _createDeck()..shuffle(_random);
    _highlightTimer?.cancel();
    final total = _totalCards;
    final badgeAssignments = List<CardBadge>.filled(total, CardBadge.none);
    final baseRows = _rowIndexMatrix.reversed.take(4).toList(growable: false);
    final weightedCandidates = <_WeightedCandidate>[];
    for (int i = 0; i < baseRows.length; i++) {
      final weight = (baseRows.length - i).toDouble();
      for (final index in baseRows[i]) {
        weightedCandidates
            .add(_WeightedCandidate(index: index, weight: weight));
      }
    }
    final greenIndices =
        _pickWeightedIndices(weightedCandidates, _challengeGreenCount);
    for (final index in greenIndices) {
      badgeAssignments[index] = CardBadge.green;
    }
    final eligibleForBlack = _rowIndexMatrix
        .take(_rowIndexMatrix.length - 1)
        .expand((row) => row)
        .where((index) => !greenIndices.contains(index))
        .toList();
    final blackIndices = <int>{};
    while (blackIndices.length < _challengeBlackCount &&
        eligibleForBlack.isNotEmpty) {
      blackIndices
          .add(eligibleForBlack[_random.nextInt(eligibleForBlack.length)]);
    }
    for (final index in blackIndices) {
      badgeAssignments[index] = CardBadge.black;
    }

    setState(() {
      _cards = deck.take(_totalCards).toList();
      _flipped = List<bool>.filled(_totalCards, false);
      _badges = badgeAssignments;
      _nextIndex = 0;
      _highlightedCard = null;
      _lastRevealedCard = null;
    });
  }

  List<PlayingCard> _createDeck() {
    final deck = <PlayingCard>[];
    for (final suit in Suit.values) {
      if (suit == Suit.joker) continue;
      for (final value in CardValue.values) {
        if (value == CardValue.joker_1 || value == CardValue.joker_2) continue;
        deck.add(PlayingCard(suit, value));
      }
    }
    return deck;
  }

  void _handleTap(int index) {
    if (_nextIndex >= _revealOrder.length) return;
    final target = _revealOrder[_nextIndex];
    if (index != target) return;

    setState(() {
      _flipped[index] = true;
      _nextIndex++;
    });
    _highlightRevealedCard(index);

    if (_nextIndex == _revealOrder.length) {
      Future.microtask(_showEndDialog);
    }
  }

  void _highlightRevealedCard(int index) {
    _highlightTimer?.cancel();
    setState(() {
      _highlightedCard = _cards[index];
      _lastRevealedCard = null;
    });
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _lastRevealedCard = _cards[index];
        _highlightedCard = null;
      });
    });
  }

  Future<void> _showEndDialog() async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = AppTheme.of(context);
        return AlertDialog(
          title: Text("Pyramide terminée", style: theme.titleMedium),
          content: Text(
            "Tu as retourné toutes les cartes.\nOn recommence ou on rentre à l'accueil ?",
            style: theme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'home'),
              child: const Text("Accueil"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'replay'),
              child: const Text("Recommencer"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (choice == 'home') {
      Navigator.pushNamedAndRemoveUntil(context, '/homepage', (route) => false);
    } else if (choice == 'replay') {
      _resetGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textPrimary),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: RotatedBox(
                quarterTurns: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacingRatio = 0.0;
                    const maxRow = _rows;
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;
                    final widthBound = availableWidth /
                        (maxRow + spacingRatio * (maxRow - 1)) /
                        1.05;
                    final heightBound = availableHeight /
                        (_rowIndexMatrix.length +
                            spacingRatio * (_rowIndexMatrix.length - 1));
                    const scaleFactor = 0.75;
                    final cardWidth = min(widthBound, heightBound) * scaleFactor;
                    final cardHeight = cardWidth * 1.4;
                    final rowSpacing = cardHeight * spacingRatio;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int row = 0; row < _rowIndexMatrix.length; row++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: row == _rowIndexMatrix.length - 1
                                  ? 0
                                  : rowSpacing,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: _buildRow(
                                indices: _rowIndexMatrix[row],
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                theme: theme,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_highlightedCard != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: min(
                          MediaQuery.of(context).size.shortestSide * 0.6, 320),
                      child: AspectRatio(
                        aspectRatio: 64 / 89,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.background,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: theme.secondary, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: PlayingCardView(
                              card: _highlightedCard!,
                              showBack: false,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_lastRevealedCard != null)
              Positioned(
                right: 16,
                top: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Dernière carte",
                      style: theme.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _cardDisplayName(_lastRevealedCard!),
                        style: theme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 16,
              bottom: 16,
              child: FloatingActionButton(
                backgroundColor: theme.primary,
                onPressed: _resetGame,
                child: const Icon(Icons.refresh),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cardDisplayName(PlayingCard card) {
    const valueNames = {
      CardValue.ace: "As",
      CardValue.two: "2",
      CardValue.three: "3",
      CardValue.four: "4",
      CardValue.five: "5",
      CardValue.six: "6",
      CardValue.seven: "7",
      CardValue.eight: "8",
      CardValue.nine: "9",
      CardValue.ten: "10",
      CardValue.jack: "Valet",
      CardValue.queen: "Dame",
      CardValue.king: "Roi",
    };
    const suitNames = {
      Suit.spades: "Pique",
      Suit.clubs: "Trefle",
      Suit.hearts: "Coeur",
      Suit.diamonds: "Carreau",
    };

    final value =
        valueNames[card.value] ?? card.value.toString().split('.').last;
    final suit = suitNames[card.suit] ?? card.suit.toString().split('.').last;
    return "$value de $suit";
  }

  Set<int> _pickWeightedIndices(
    List<_WeightedCandidate> candidates,
    int count,
  ) {
    final selected = <int>{};
    final pool = List<_WeightedCandidate>.from(candidates);
    while (selected.length < count && pool.isNotEmpty) {
      final totalWeight =
          pool.fold<double>(0, (sum, candidate) => sum + candidate.weight);
      final target = _random.nextDouble() * totalWeight;
      double cumulative = 0;
      _WeightedCandidate? chosen;
      for (final candidate in pool) {
        cumulative += candidate.weight;
        if (target <= cumulative) {
          chosen = candidate;
          break;
        }
      }
      chosen ??= pool.last;
      selected.add(chosen.index);
      pool.removeWhere((candidate) => candidate.index == chosen!.index);
    }
    return selected;
  }

  List<Widget> _buildRow({
    required List<int> indices,
    required double cardWidth,
    required double cardHeight,
    required AppTheme theme,
  }) {
    const spacingRatio = 0.0;
    final children = <Widget>[];
    for (final index in indices) {
      if (children.isNotEmpty) {
        children.add(SizedBox(width: cardWidth * spacingRatio));
      }
      children.add(_buildCard(
        index: index,
        width: cardWidth,
        height: cardHeight,
        theme: theme,
      ));
    }
    return children;
  }

  Widget _buildCard({
    required int index,
    required double width,
    required double height,
    required AppTheme theme,
  }) {
    final isRevealed = _flipped[index];
    final isActive =
        _nextIndex < _revealOrder.length && _revealOrder[_nextIndex] == index;

    return GestureDetector(
      onTap: isActive ? () => _handleTap(index) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isActive ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? theme.secondary : Colors.black26,
              width: isActive ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _CardContent(
            card: _cards[index],
            showBack: !isRevealed,
            badge: _badges[index],
            isRevealed: isRevealed,
          ),
        ),
      ),
    );
  }
}

enum CardBadge { none, green, black }

class _WeightedCandidate {
  const _WeightedCandidate({required this.index, required this.weight});

  final int index;
  final double weight;
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.card,
    required this.showBack,
    required this.badge,
    required this.isRevealed,
  });

  final PlayingCard card;
  final bool showBack;
  final CardBadge badge;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    final overlayColor = _overlayColor(badge, isRevealed);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: borderRadius.subtract(BorderRadius.circular(2)),
          child: PlayingCardView(
            card: card,
            showBack: showBack,
            elevation: 0,
          ),
        ),
        if (overlayColor != null)
          ClipRRect(
            borderRadius: borderRadius.subtract(BorderRadius.circular(2)),
            child: DecoratedBox(
              decoration: BoxDecoration(color: overlayColor),
            ),
          ),
      ],
    );
  }

  Color? _overlayColor(CardBadge badge, bool isRevealed) {
    switch (badge) {
      case CardBadge.green:
        return Colors.green.withOpacity(isRevealed ? 0.35 : 0.75);
      case CardBadge.black:
        return Colors.black.withOpacity(isRevealed ? 0.45 : 0.8);
      case CardBadge.none:
        return null;
    }
  }
}
