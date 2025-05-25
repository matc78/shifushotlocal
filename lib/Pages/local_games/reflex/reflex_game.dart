// Page Flutter avec animations pour "ReflexGamePage"
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:confetti/confetti.dart';

class ReflexGamePage extends StatefulWidget {
  const ReflexGamePage({super.key});

  @override
  State<ReflexGamePage> createState() => _ReflexGamePageState();
}

class _ReflexGamePageState extends State<ReflexGamePage>
    with TickerProviderStateMixin {
  bool _waiting = false;
  bool _canTap = false;
  String _message = 'Appuie sur "Démarrer" pour commencer';
  Duration? _bestReaction;
  bool _newRecord = false;
  bool _hasDisplayedNewRecordMessage = false;
  Timer? _timer;
  Timer? _reactionTimer;
  late DateTime _startTime;
  late DateTime? _reactionStart;
  Duration _currentReaction = Duration.zero;
  late ConfettiController _confettiController;
  late AnimationController _startButtonController;
  late AnimationController _messageController;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _startButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reactionTimer?.cancel();
    _confettiController.dispose();
    _startButtonController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      final scores = Map<String, dynamic>.from(data['high_scores'] ?? {});
      final int millis = scores['reflex_game'] ?? 9999;
      setState(() {
        _bestReaction = Duration(milliseconds: millis);
      });
    }
  }

  Future<void> _updateHighScoreIfNeeded(Duration currentReaction) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_bestReaction == null || currentReaction < _bestReaction!) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      final scores = Map<String, dynamic>.from(doc.data()?['high_scores'] ?? {});
      scores['reflex_game'] = currentReaction.inMilliseconds;
      await docRef.update({'high_scores': scores});
      setState(() {
        _bestReaction = currentReaction;
        _newRecord = true;
        _hasDisplayedNewRecordMessage = false;
      });
      _confettiController.play();
    }
  }

  void _startGame() {
    setState(() {
      _waiting = true;
      _canTap = false;
      _newRecord = false;
      _hasDisplayedNewRecordMessage = true;
      _message = 'Prépare-toi...';
      _currentReaction = Duration.zero;
    });

    _startButtonController.reverse();
    final delay = Duration(seconds: Random().nextInt(5) + 2);
    _timer?.cancel();
    _reactionTimer?.cancel();
    _timer = Timer(delay, () {
      setState(() {
        _canTap = true;
        _startTime = DateTime.now();
        _reactionStart = DateTime.now();
        _message = 'APPUIE MAINTENANT !';
      });
      _reactionTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        setState(() {
          _currentReaction = DateTime.now().difference(_reactionStart!);
        });
      });
    });
  }

  void _handleTap() {
    if (_waiting && !_canTap) {
      setState(() {
        _message = 'Trop tôt ! Réessaie.';
        _waiting = false;
        _canTap = false;
      });
      _timer?.cancel();
    } else if (_canTap) {
      final now = DateTime.now();
      final reaction = now.difference(_startTime);
      _reactionTimer?.cancel();
      setState(() {
        _waiting = false;
        _canTap = false;
        _message = 'Temps de réaction : ${reaction.inMilliseconds} ms';
      });
      _updateHighScoreIfNeeded(reaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: _canTap ? theme.secondary : theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: BackButton(
          color: theme.textPrimary,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/select_game');
          },
        ),
        title: Text("Réflexe Challenge", style: theme.titleMedium),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (_message == 'Prépare-toi...')
                        ? FadeTransition(
                            opacity: _messageController,
                            child: Text(
                              _message,
                              textAlign: TextAlign.center,
                              style: theme.titleMedium,
                            ),
                          )
                        : Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: theme.titleMedium,
                          ),
                    const SizedBox(height: 20),
                    if (_canTap)
                      Text(
                        '${_currentReaction.inMilliseconds} ms',
                        style: theme.titleLarge.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!_waiting)
                      ScaleTransition(
                        scale: _startButtonController.drive(Tween(begin: 0.8, end: 1.0)),
                        child: ElevatedButton(
                          onPressed: () {
                            _startGame();
                            _startButtonController.forward();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 32.0),
                          ),
                          child: Text('Démarrer', style: theme.buttonText),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_bestReaction != null)
                      Text(
                        '🏆 Record personnel : ${_bestReaction!.inMilliseconds} ms',
                        style: theme.bodyMedium,
                      ),
                    if (_newRecord && !_hasDisplayedNewRecordMessage)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          '🎉 Nouveau record personnel !',
                          style: theme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [theme.primary, theme.secondary, Colors.green],
            ),
          ),
        ],
      ),
    );
  }
}