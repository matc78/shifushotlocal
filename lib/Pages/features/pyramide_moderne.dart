import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';

import '../../theme/app_theme.dart';

class PyramideModernePage extends StatefulWidget {
  const PyramideModernePage({super.key});

  @override
  State<PyramideModernePage> createState() => _PyramideModernePageState();
}

class _PyramideModernePageState extends State<PyramideModernePage>
    with SingleTickerProviderStateMixin {
  static _PyramideSavedState? _savedState;
  static const int _rows = 6;
  static const int _doubleDrinkCount = 7;

  final Random _random = Random();
  final PageController _pageController = PageController(viewportFraction: 0.72);
  int _currentPage = 0;

  late final List<List<int>> _rowIndexMatrix = _buildRowIndices();
  late final List<int> _revealOrder = _buildRevealOrder();
  late final List<int> _rowByCardIndex = _buildRowLookup();

  late List<PlayingCard> _cards;
  late List<bool> _flipped;
  late List<bool> _doubleDrinks;
  late List<bool> _shotAssignments;
  int _nextSequenceIndex = 0;
  bool _isFlipLocked = false;
  bool _showShotOverlay = false;
  bool _shotsEnabled = true;
  bool _doublesEnabled = true;
  late final AnimationController _skullController;
  late final Animation<double> _skullBounce;

  int get _totalCards => (_rows * (_rows + 1)) ~/ 2;

  @override
  void initState() {
    super.initState();
    _skullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _skullBounce = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _skullController, curve: Curves.easeInOut),
    );
    _restoreOrStartFresh();
  }

  List<bool> _buildDoubleDrinkAssignments() {
    final assignments = List<bool>.filled(_totalCards, false);
    final baseRows = _rowIndexMatrix.reversed.take(3).toList(growable: false);
    final weighted = <_WeightedCandidate>[];
    for (int i = 0; i < baseRows.length; i++) {
      final weight = (baseRows.length - i).toDouble();
      for (final index in baseRows[i]) {
        weighted.add(_WeightedCandidate(index: index, weight: weight));
      }
    }
    final selected = _pickWeightedIndices(weighted, _doubleDrinkCount);
    for (final index in selected) {
      assignments[index] = true;
    }
    return assignments;
  }

  List<bool> _noAssignments() =>
      List<bool>.filled(_totalCards, false, growable: false);

  List<bool> _buildShotAssignments() {
    final assignments = List<bool>.filled(_totalCards, false);
    final lastIndex = _totalCards - 1;
    assignments[lastIndex] = true;
    final available = List<int>.generate(_totalCards - 1, (i) => i)
      ..shuffle(_random);
    for (int i = 0; i < min(2, available.length); i++) {
      assignments[available[i]] = true;
    }
    return assignments;
  }

  void _applyShotOverrides() {
    if (_shotAssignments.length != _doubleDrinks.length) return;
    for (int i = 0; i < _shotAssignments.length; i++) {
      if (_shotAssignments[i]) {
        _doubleDrinks[i] = false;
      }
    }
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

  @override
  void dispose() {
    _skullController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<List<int>> _buildRowIndices() {
    final rows = <List<int>>[];
    var running = 0;
    for (int length = 1; length <= _rows; length++) {
      rows.add(List<int>.generate(length, (_) => running++));
    }
    return rows;
  }

  List<int> _buildRowLookup() {
    final lookup = List<int>.filled(_totalCards, 0);
    for (int row = 0; row < _rowIndexMatrix.length; row++) {
      for (final index in _rowIndexMatrix[row]) {
        lookup[index] = row;
      }
    }
    return lookup;
  }

  List<int> _buildRevealOrder() {
    final order = <int>[];
    for (int row = _rowIndexMatrix.length - 1; row >= 0; row--) {
      order.addAll(_rowIndexMatrix[row]);
    }
    return order;
  }

  void _resetGame() {
    _clearSavedState();
    final deck = _createDeck()..shuffle(_random);
    setState(() {
      _nextSequenceIndex = 0;
      _cards = deck.take(_totalCards).toList();
      _flipped = List<bool>.filled(_totalCards, false);
      _currentPage = 0;
      _doubleDrinks =
          _doublesEnabled ? _buildDoubleDrinkAssignments() : _noAssignments();
      _shotAssignments =
          _shotsEnabled ? _buildShotAssignments() : _noAssignments();
      _applyShotOverrides();
      _isFlipLocked = false;
      _showShotOverlay = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      _pageController.jumpToPage(0);
    });
  }

  Future<void> _confirmRestart() async {
    final shouldRestart = await _showActionConfirmation(
      title: "Recommencer la pyramide ?",
      message: "Toutes les cartes seront remélangées.",
      confirmLabel: "Relancer",
    );
    if (shouldRestart) {
      _resetGame();
    }
  }

  Future<void> _confirmBackNavigation() async {
    _saveCurrentState();
    if (mounted) {
      Navigator.maybePop(context);
    }
  }

  List<PlayingCard> _createDeck() {
    final deck = <PlayingCard>[];
    for (final suit in Suit.values) {
      if (suit == Suit.joker) continue;
      for (final value in CardValue.values) {
        if (value == CardValue.joker_1 || value == CardValue.joker_2) {
          continue;
        }
        deck.add(PlayingCard(suit, value));
      }
    }
    return deck;
  }

  Future<void> _handleCardTap(int sequenceIndex) async {
    if (_isFlipLocked) return;
    if (sequenceIndex != _nextSequenceIndex) return;
    final cardIndex = _revealOrder[sequenceIndex];
    setState(() {
      _isFlipLocked = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final isShotCard = _shotAssignments[cardIndex];
    setState(() {
      _flipped[cardIndex] = true;
      _nextSequenceIndex++;
      _isFlipLocked = isShotCard;
    });
    if (isShotCard) {
      _triggerShotOverlay();
    } else {
      setState(() {
        _isFlipLocked = false;
      });
    }
    if (_pageController.hasClients && _revealOrder.isNotEmpty) {
      final target = (_nextSequenceIndex - 1).clamp(0, _revealOrder.length - 1);
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    if (_nextSequenceIndex == _revealOrder.length) {
      Future.microtask(_showEndDialog);
    }
  }

  void _triggerShotOverlay() {
    setState(() {
      _showShotOverlay = true;
    });
    _skullController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showShotOverlay = false;
        _isFlipLocked = false;
      });
      _skullController.stop();
      _skullController.reset();
    });
  }

  void _restoreOrStartFresh() {
    final cache = _savedState;
    if (cache == null) {
      _resetGame();
      return;
    }
    setState(() {
      _cards = List<PlayingCard>.from(cache.cards);
      _flipped = List<bool>.from(cache.flipped);
      _doubleDrinks = List<bool>.from(cache.doubleDrinks);
      _shotAssignments = List<bool>.from(cache.shotAssignments);
      _nextSequenceIndex = cache.nextIndex;
      _currentPage = cache.currentPage;
      _shotsEnabled = cache.shotsEnabled;
      _doublesEnabled = cache.doublesEnabled;
      _isFlipLocked = false;
      _showShotOverlay = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
    _savedState = null;
  }

  void _saveCurrentState() {
    if (!mounted || _cards.isEmpty) return;
    _savedState = _PyramideSavedState(
      cards: List<PlayingCard>.from(_cards),
      flipped: List<bool>.from(_flipped),
      doubleDrinks: List<bool>.from(_doubleDrinks),
      shotAssignments: List<bool>.from(_shotAssignments),
      nextIndex: _nextSequenceIndex,
      currentPage: _currentPage,
      shotsEnabled: _shotsEnabled,
      doublesEnabled: _doublesEnabled,
    );
  }

  void _clearSavedState() {
    _savedState = null;
  }

  Future<void> _showEndDialog() async {
    final theme = AppTheme.of(context);
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Pyramide terminée", style: theme.titleMedium),
          content: Text(
            "Toutes les cartes ont été retournées.\nOn recommence ?",
            style: theme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'home'),
              child: const Text("Accueil"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'replay'),
              child: const Text("Relancer"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (choice == 'home') {
      _clearSavedState();
      Navigator.pushNamedAndRemoveUntil(context, '/homepage', (route) => false);
    } else if (choice == 'replay') {
      _resetGame();
    }
  }

  Future<bool> _showActionConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final theme = AppTheme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: theme.titleMedium),
          content: Text(message, style: theme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final bool isShotMoment = _showShotOverlay;
    final Color appBarColor = isShotMoment ? Colors.black : theme.background;
    final Color appBarForeground =
        isShotMoment ? Colors.white : theme.textPrimary;

    return WillPopScope(
      onWillPop: () async {
        _saveCurrentState();
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: appBarColor,
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: appBarForeground),
            onPressed: _confirmBackNavigation,
          ),
          title: Text(
            "Pyramide moderne",
            style: theme.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: appBarForeground,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: appBarForeground),
              onPressed: _confirmRestart,
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_nextSequenceIndex == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ToggleTile(
                              label: "Activer les shots",
                              value: _shotsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _shotsEnabled = value ?? true;
                                  if (_nextSequenceIndex == 0) {
                                    _shotAssignments = _shotsEnabled
                                        ? _buildShotAssignments()
                                        : _noAssignments();
                                    _applyShotOverrides();
                                  }
                                });
                              },
                            ),
                            const Divider(
                              color: Colors.white30,
                              height: 0,
                            ),
                            _ToggleTile(
                              label: "Activer les gorgées doubles",
                              value: _doublesEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _doublesEnabled = value ?? true;
                                  if (_nextSequenceIndex == 0) {
                                    _doubleDrinks = _doublesEnabled
                                        ? _buildDoubleDrinkAssignments()
                                        : _noAssignments();
                                    _applyShotOverrides();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SizedBox(
                        height:
                            min(MediaQuery.of(context).size.height * 0.45, 320),
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemCount: _revealOrder.length,
                          padEnds: false,
                          itemBuilder: (context, sequenceIndex) {
                            final cardIndex = _revealOrder[sequenceIndex];
                            return _CarouselCard(
                              sequenceIndex: sequenceIndex,
                              isCurrent: _currentPage == sequenceIndex,
                              isActive: _nextSequenceIndex == sequenceIndex,
                              isRevealed: _flipped[cardIndex],
                              isDoubled: _doubleDrinks[cardIndex],
                              isShot: _shotAssignments[cardIndex],
                              card: _cards[cardIndex],
                              stage: _stageForRow(_rowByCardIndex[cardIndex]),
                              onTap: () => _handleCardTap(sequenceIndex),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _ProgressOverview(
                    progress: _revealOrder.isEmpty
                        ? 0
                        : _nextSequenceIndex / _revealOrder.length,
                    currentIndex: _nextSequenceIndex,
                    total: _revealOrder.length,
                    theme: theme,
                  ),
                ],
              ),
            ),
            if (_showShotOverlay)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _skullController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _skullBounce.value),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "☠️",
                          style: TextStyle(fontSize: 120),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "SHOT !",
                          style: theme.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _StageInfo _stageForRow(int rowIndex) {
    final stageFromBottom = _rows - rowIndex;
    final colors = [
      Colors.cyan,
      Colors.green,
      Colors.amber,
      Colors.orange,
      Colors.pink,
      Colors.deepPurple,
    ];
    final color = colors[(stageFromBottom - 1).clamp(0, colors.length - 1)];
    final title =
        stageFromBottom == 1 ? "1 gorgée" : "$stageFromBottom gorgées";
    return _StageInfo(title: title, color: color, drinks: stageFromBottom);
  }
}

class _StageInfo {
  const _StageInfo({
    required this.title,
    required this.color,
    required this.drinks,
  });

  final String title;
  final Color color;
  final int drinks;
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.sequenceIndex,
    required this.isCurrent,
    required this.card,
    required this.isActive,
    required this.isRevealed,
    required this.isDoubled,
    required this.isShot,
    required this.stage,
    required this.onTap,
  });

  final int sequenceIndex;
  final bool isCurrent;
  final PlayingCard card;
  final bool isActive;
  final bool isRevealed;
  final bool isDoubled;
  final bool isShot;
  final _StageInfo stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final padding =
        EdgeInsets.only(left: sequenceIndex == 0 ? 20 : 12, right: 12);
    final backgroundColor = (isShot && isRevealed)
        ? Colors.black
        : stage.color.withOpacity(isActive ? 0.95 : 0.75);
    final isClickable = isActive && !isRevealed;
    final showShotLabel = isShot && isRevealed;
    final showDoubleLabel = !showShotLabel && isRevealed && isDoubled;
    final headerText = showShotLabel
        ? "SHOT"
        : showDoubleLabel
            ? "${stage.drinks * 2} gorgées"
            : stage.title;
    final headerStyle = showShotLabel
        ? theme.titleLarge.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.w900,
          )
        : showDoubleLabel
            ? theme.titleLarge.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w800,
              )
            : theme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: headerStyle,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(headerText),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isActive ? onTap : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (isActive || isCurrent || isRevealed) ? 1 : 0.3,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isClickable
                      ? 1.05
                      : isActive
                          ? 1.02
                          : 0.96,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isClickable
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                        width: isClickable
                            ? 5
                            : isActive
                                ? 3
                                : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stage.color.withOpacity(isClickable
                              ? 0.65
                              : isActive
                                  ? 0.45
                                  : 0.2),
                          blurRadius: isClickable
                              ? 30
                              : isActive
                                  ? 22
                                  : 12,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AspectRatio(
                                aspectRatio: 64 / 89,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    PlayingCardView(
                                      card: card,
                                      showBack: !isRevealed,
                                      elevation: 0,
                                    ),
                                    if (!isRevealed)
                                      Container(
                                        color: Colors.black.withOpacity(
                                            isClickable ? 0.12 : 0.35),
                                      ),
                                    if (isShot && isRevealed)
                                      Container(
                                        color: Colors.black.withOpacity(0.5),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "SHOT",
                                          style: theme.titleLarge.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (isClickable)
                                      IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color:
                                                theme.primary.withOpacity(0.25),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isRevealed && isDoubled)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.shade700.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                "x2",
                                style: theme.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        if (isClickable)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: _TapHint(theme: theme),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({
    required this.progress,
    required this.currentIndex,
    required this.total,
    required this.theme,
  });

  final double progress;
  final int currentIndex;
  final int total;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final formattedIndex = min(currentIndex + 1, safeTotal);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuad,
            builder: (context, value, _) {
              return SizedBox(
                height: 18,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.textPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            "Carte $formattedIndex sur $total",
            textAlign: TextAlign.center,
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _WeightedCandidate {
  const _WeightedCandidate({required this.index, required this.weight});

  final int index;
  final double weight;
}

class _PyramideSavedState {
  const _PyramideSavedState({
    required this.cards,
    required this.flipped,
    required this.doubleDrinks,
    required this.shotAssignments,
    required this.nextIndex,
    required this.currentPage,
    required this.shotsEnabled,
    required this.doublesEnabled,
  });

  final List<PlayingCard> cards;
  final List<bool> flipped;
  final List<bool> doubleDrinks;
  final List<bool> shotAssignments;
  final int nextIndex;
  final int currentPage;
  final bool shotsEnabled;
  final bool doublesEnabled;
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        label,
        style: theme.bodyLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      activeColor: Colors.white,
      checkColor: theme.primary,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}

class _TapHint extends StatefulWidget {
  const _TapHint({required this.theme});

  final AppTheme theme;

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.05).animate(_controller),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, size: 16),
              const SizedBox(width: 6),
              Text(
                "Tape pour retourner",
                style: widget.theme.titleMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
