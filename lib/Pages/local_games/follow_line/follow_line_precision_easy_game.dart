import 'dart:ui';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowLinePrecisionEasy extends StatefulWidget {
  const FollowLinePrecisionEasy({super.key});

  @override
  State<FollowLinePrecisionEasy> createState() => _FollowLinePrecisionEasyState();
}

class _FollowLinePrecisionEasyState extends State<FollowLinePrecisionEasy> {
  final List<Offset> userPath = [];
  late Path linePath;
  double precision = 0;
  double highScore = 0;
  bool gameOver = false;
  bool hasStarted = false;
  double screenWidth = 0;
  Offset startCircle = const Offset(60, 150);
  final double startRadius = 25;
  Rect endBox = Rect.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    linePath = _createLinePath();
    double endY = 150 + 2 * 150; // même logique que ton tracé
    endBox = Rect.fromLTWH(screenWidth - 120, endY - 30, 60, 60);
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      final scores = Map<String, dynamic>.from(data['high_scores'] ?? {});
      setState(() {
        highScore = (scores['follow_line_precision_easy'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _updateHighScoreIfNeeded(double currentScore) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (currentScore > highScore) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      final scores = Map<String, dynamic>.from(doc.data()?['high_scores'] ?? {});
      scores['follow_line_precision_easy'] = currentScore;
      await docRef.update({'high_scores': scores});
      setState(() {
        highScore = currentScore;
      });
    }
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

  void _endGame(Offset releasePoint) {
    int inLine = 0;
    int outLine = 0;

    for (final point in userPath) {
      if (_isNearLine(point)) {
        inLine++;
      } else {
        outLine++;
      }
    }

    final total = userPath.length;
    final basePrecision = total == 0 ? 0 : inLine / total;
    final penalty = total == 0 ? 1.0 : outLine / total;

    double score = (basePrecision * (1.0 - penalty)) * 100;

    if (!endBox.contains(releasePoint)) {
      score = score.clamp(0, 0);
    }

    setState(() {
      precision = score;
      gameOver = true;
    });

    _updateHighScoreIfNeeded(score);
  }

  void _restartGame() {
    setState(() {
      userPath.clear();
      precision = 0;
      gameOver = false;
      hasStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('Mode Précision - Facile', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              final isInStartCircle = (details.localPosition - startCircle).distance <= startRadius;

              if (isInStartCircle && gameOver) {
                _restartGame();
              }

              if (isInStartCircle && !gameOver) {
                setState(() {
                  hasStarted = true;
                  userPath.add(details.localPosition);
                });
              }
            },
            onPanUpdate: (details) {
              if (!hasStarted || gameOver) return;
              setState(() {
                userPath.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              if (!hasStarted || gameOver) return;
              final Offset endPoint = userPath.isNotEmpty ? userPath.last : Offset.zero;
              _endGame(endPoint);
            },
            child: Container(
              color: theme.background,
              child: CustomPaint(
                painter: _LinePainter(linePath, userPath, startCircle, startRadius, endBox),
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
                  gameOver
                      ? '🎯 Précision finale : ${precision.toStringAsFixed(1)} %'
                      : 'Touchez le rond pour commencer',
                  style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (gameOver)
                  Text('🏆 Record personnel : ${highScore.toStringAsFixed(1)} %', style: theme.bodyMedium),
              ],
            ),
          ),
          if (gameOver || hasStarted)
            Positioned(
              bottom: 30,
              left: MediaQuery.of(context).size.width / 2 - 70,
              child: ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: Text("Rejouer", style: theme.buttonText),
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

  _LinePainter(this.line, this.userPoints, this.start, this.radius, this.endBox);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 50;

    final pathPaint = Paint()
      ..color = Colors.red
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
