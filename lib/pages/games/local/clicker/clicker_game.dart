import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';
import 'package:shifushotlocal/routes.dart';

class ClickerGame extends StatefulWidget {
  const ClickerGame({super.key});

  @override
  State<ClickerGame> createState() => _ClickerGameState();
}

class _ClickerGameState extends State<ClickerGame> {
  String playerName = "Moi";
  int score = 0;
  bool isGameActive = false;
  bool showStartButton = true;
  Timer? timer;
  int timeLeft = 10;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      try {
        final doc = await docRef.get();
        final data = doc.data() ?? {};
        final highScores = Map<String, dynamic>.from(data['high_scores'] ?? {});
        final userName = data['name'] ?? "Moi";

        setState(() {
          playerName = userName;
          highScore = (highScores['clicker_game'] ?? 0) as int;
        });
      } catch (e) {
        debugPrint("❌ Erreur récupération des données : $e");
      }
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        timeLeft--;
      });

      if (timeLeft <= 0) {
        timer.cancel();
        endGame();
      }
    });
  }

  void incrementScore() {
    if (!isGameActive) return;
    setState(() {
      score++;
    });
  }

  void startClickingPhase() {
    setState(() {
      isGameActive = true;
      showStartButton = false;
      score = 0;
      timeLeft = 10;
    });
    startTimer();
  }

  void endGame() {
    setState(() {
      isGameActive = false;
    });
    showGameOverDialog();
  }

  void showGameOverDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Mise à jour du high score si nécessaire
    if (uid != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      try {
        final doc = await docRef.get();
        final data = doc.data() ?? {};
        final highScores = Map<String, dynamic>.from(data['high_scores'] ?? {});
        final int existingScore = (highScores['clicker_game'] ?? 0) as int;

        if (score > existingScore) {
          highScores['clicker_game'] = score;
          await docRef.update({'high_scores': highScores});
          setState(() {
            highScore = score;
          });
          debugPrint("🎉 Nouveau record personnel : $score");
        } else {
          debugPrint("ℹ️ Score actuel : $score (record : $existingScore)");
        }
      } catch (e) {
        debugPrint("❌ Erreur mise à jour du high score : $e");
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = AppTheme.of(context); // Place ici dans le builder
        return AlertDialog(
          title: const Text(
            "Game Over!",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Score final :",
                style: TextStyle(
                  fontSize: 20,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$score",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Record personnel : $highScore",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              if (score == highScore && score > 0)
                const Text(
                  "🎉 Nouveau record personnel !",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 20, 233, 27),
                  ),
                ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              children: [
                SizedBox(
                  width: 180,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ClickerGame()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary, // 🎨 couleur du thème
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Rejouer"),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 180,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, Routes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.secondary, // 🎨 couleur secondaire du thème
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Accueil"),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return AppShell(
      title: 'Le Clicker',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            // Score / state card
            SectionCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    playerName.toUpperCase(),
                    style: theme.overline
                        .copyWith(color: theme.textMuted, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (rect) =>
                        theme.brandGradient.createShader(rect),
                    child: Text(
                      '$score',
                      style: theme.displayLarge.copyWith(
                          color: Colors.white, fontSize: 64, height: 1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('SCORE',
                      style: theme.overline.copyWith(color: theme.textMuted)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(label: 'TEMPS', value: '${timeLeft}s'),
                      _Stat(label: 'RECORD', value: '$highScore'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: showStartButton
                    ? GradientButton(
                        label: "C'EST PARTI !",
                        icon: Icons.play_arrow_rounded,
                        onPressed: startClickingPhase,
                        height: 64,
                      )
                    : _BigTapTarget(onTap: incrementScore),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      children: [
        Text(label,
            style: theme.overline
                .copyWith(color: theme.textMuted, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(value,
            style: theme.titleMedium.copyWith(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

class _BigTapTarget extends StatelessWidget {
  const _BigTapTarget({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
          decoration: BoxDecoration(
            gradient: theme.brandGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: theme.glowShadow,
          ),
          child: Text(
            'TAP TAP TAP\nPLUS VITE !!',
            textAlign: TextAlign.center,
            style: theme.titleLarge.copyWith(
              color: Colors.white,
              fontSize: 28,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
