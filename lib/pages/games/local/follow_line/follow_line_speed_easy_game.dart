import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowLineSpeedEasy extends StatefulWidget {
  const FollowLineSpeedEasy({super.key});

  @override
  State<FollowLineSpeedEasy> createState() => _FollowLineSpeedEasyState();
}

class _FollowLineSpeedEasyState extends State<FollowLineSpeedEasy> {
  final List<Offset> userPath = [];
  late Path linePath;
  double screenWidth = 0;
  Offset startCircle = const Offset(60, 150);
  final double startRadius = 25;
  Rect endBox = Rect.zero;

  bool isRunning = false;
  bool isValid = true;
  bool hasStarted = false;
  Duration timeLeft = Duration.zero;
  Timer? countdownTimer;
  int level = 1;
  int highScore = 1;
  final List<int> levelDurations = [20, 10, 7, 5, 3, 2, 1];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    linePath = _createLinePath();
    double endY = 150 + 2 * 150;
    endBox = Rect.fromLTWH(screenWidth - 120, endY - 30, 60, 60);
    timeLeft = Duration(seconds: levelDurations[level - 1]);
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      final scores = Map<String, dynamic>.from(data['high_scores'] ?? {});
      final int score = scores['follow_line_speed_easy'] ?? 1;
      setState(() {
        highScore = score;
      });
    }
  }

  Future<void> _updateHighScore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();
    final scores = Map<String, dynamic>.from(doc.data()?['high_scores'] ?? {});

    if ((scores['follow_line_speed_easy'] ?? 0) < level) {
      scores['follow_line_speed_easy'] = level;
      await docRef.update({'high_scores': scores});
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Path _createLinePath() {
    final path = Path();
    double yStart = 150;
    double yStep = 150;
    double width = screenWidth;
    double margin = 60;

    path.moveTo(margin, yStart);
    path.lineTo(width - margin, yStart);
    path.lineTo(width - margin, yStart + yStep);
    path.lineTo(margin, yStart + yStep);
    path.lineTo(margin, yStart + 2 * yStep);
    path.lineTo(width - margin, yStart + 2 * yStep);

    return path;
  }

  bool _isNearLine(Offset point) {
    final pathMetrics = linePath.computeMetrics();
    for (final metric in pathMetrics) {
      for (double i = 0; i < metric.length; i += 5) {
        final pos = metric.getTangentForOffset(i)!.position;
        if ((point - pos).distance <= 23) return true;
      }
    }
    return false;
  }

  void _startTimer() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        timeLeft -= const Duration(milliseconds: 100);
        if (timeLeft.inMilliseconds <= 0) {
          timer.cancel();
          isRunning = false;
          _showGameOver();
        }
      });
    });
  }

  void _restartGame() {
    setState(() {
      userPath.clear();
      isValid = true;
      hasStarted = false;
      timeLeft = Duration(seconds: levelDurations[level - 1]);
    });
  }

  void _showGameOver() {
    final theme = AppTheme.of(context);
    _updateHighScore();
    setState(() {
      level = 1;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'GAME OVER',
          style: TextStyle(
            color: theme.secondary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Level : $level',
          style: theme.bodyMedium,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejouer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accueil'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    final theme = AppTheme.of(context);
    final bool isLastLevel = level > levelDurations.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          message,
          style: TextStyle(
            color: theme.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: isLastLevel
            ? [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Rejouer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accueil'),
                ),
              ]
            : [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continuer'),
                ),
              ],
      ),
    );
  }

  void _validateSuccess() {
    // Calcul de la précision
    int inLine = 0;
    for (final point in userPath) {
      if (_isNearLine(point)) inLine++;
    }
    final double precision = userPath.isEmpty ? 0 : (inLine / userPath.length);

    // Validation uniquement si précision parfaite ET que le tracé est valide
    if (precision < 1.0 || !isValid) return;

    countdownTimer?.cancel();
    setState(() {
      isRunning = false;
    });

    if (level < levelDurations.length) {
      level++;
      _showSuccessMessage("Level $level");
    } else {
      _updateHighScore();
      _showSuccessMessage("🎉 Bravo ! Niveau max atteint");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('Mode Rapidité - Facile', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              if ((details.localPosition - startCircle).distance <= startRadius) {
                setState(() {
                hasStarted = true;
                if (!isRunning) {
                  isRunning = true;
                  _startTimer();
                }
                userPath.clear();
                userPath.add(details.localPosition);
                isValid = true;
                });
                _startTimer();
              }
            },
            onPanUpdate: (details) {
              if (!hasStarted || !isRunning) return;
              final point = details.localPosition;
              if (_isNearLine(point)) {
                setState(() {
                  userPath.add(point);
                });
                if (endBox.contains(point)) {
                  _validateSuccess();
                }
              } else {
                setState(() {
                  isValid = false;
                  userPath.clear();
                });
              }
            },
            onPanEnd: (_) {
              setState(() {
                hasStarted = false;
              });
            },
            child: Container(
              color: theme.background,
              child: CustomPaint(
                painter: _LinePainter(linePath, userPath, startCircle, startRadius, endBox, isValid),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏱ Temps restant : ${timeLeft.inSeconds}.${(timeLeft.inMilliseconds % 1000) ~/ 100}s',
                  style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('🎯 Niveau : $level', style: theme.bodyMedium),
                Text('🏆 Record : $highScore', style: theme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Path line;
  final List<Offset> userPoints;
  final Offset start;
  final double radius;
  final Rect endBox;
  final bool isValid;

  _LinePainter(this.line, this.userPoints, this.start, this.radius, this.endBox, this.isValid);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 50;

    final pathPaint = Paint()
      ..color = isValid ? Colors.red : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawPath(line, linePaint);

    if (userPoints.isNotEmpty) {
      final userPath = Path();
      userPath.moveTo(userPoints.first.dx, userPoints.first.dy);
      for (final p in userPoints) {
        userPath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(userPath, pathPaint);
    }

    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawCircle(start, radius, startPaint);

    final endPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawRect(endBox, endPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
