import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shifushotlocal/theme/app_theme.dart';

class ClickerGame extends StatefulWidget {
  const ClickerGame({super.key});

  @override
  _ClickerGameState createState() => _ClickerGameState();
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
        print("❌ Erreur récupération des données : $e");
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
          print("🎉 Nouveau record personnel : $score");
        } else {
          print("ℹ️ Score actuel : $score (record : $existingScore)");
        }
      } catch (e) {
        print("❌ Erreur mise à jour du high score : $e");
      }
    }

    await Future.delayed(const Duration(seconds: 1));

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
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      Navigator.pushReplacementNamed(context, '/homepage');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary, // 🎨 couleur secondaire du thème
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          "Le Clicker",
          style: theme.titleMedium,
        ),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playerName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'High Score personnel : $highScore',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Temps restant : $timeLeft",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Score: $score",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (showStartButton)
                    ElevatedButton(
                      onPressed: startClickingPhase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "C'EST PARTI !",
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  if (!showStartButton)
                    ElevatedButton(
                      onPressed: incrementScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 150),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "TAPE MOI !!\nMAIS TAPE PLUS VITE !!\nP****N J'ADORE ÇA !!",
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
