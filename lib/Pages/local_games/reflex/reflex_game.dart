import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class ReflexGamePage extends StatefulWidget {
  const ReflexGamePage({super.key});

  @override
  State<ReflexGamePage> createState() => _ReflexGamePageState();
}

class _ReflexGamePageState extends State<ReflexGamePage> {
  bool _waiting = false;
  bool _canTap = false;
  String _message = 'Appuie sur "Démarrer" pour commencer';
  Duration? _bestReaction;
  bool _newRecord = false;
  bool _hasDisplayedNewRecordMessage = false;
  Timer? _timer;

  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
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
        _hasDisplayedNewRecordMessage = false; // Permet l'affichage unique
      });
    }
  }

  void _startGame() {
    setState(() {
      _waiting = true;
      _canTap = false;
      _newRecord = false;
      _message = 'Prépare-toi...';
      _hasDisplayedNewRecordMessage = true; // On cache le message au redémarrage
    });

    final delay = Duration(seconds: Random().nextInt(5) + 2);
    _timer?.cancel();
    _timer = Timer(delay, () {
      setState(() {
        _canTap = true;
        _startTime = DateTime.now();
        _message = 'APPUIE MAINTENANT !';
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
        title: Text(
          "Réflexe Challenge",
          style: theme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: theme.titleMedium,
                ),
                const SizedBox(height: 20),
                if (!_waiting)
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 32.0,
                      ),
                    ),
                    child: Text(
                      'Démarrer',
                      style: theme.buttonText,
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
    );
  }
}
