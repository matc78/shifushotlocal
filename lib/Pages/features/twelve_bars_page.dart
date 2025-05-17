import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../../../theme/app_theme.dart';

class TwelveBarsPage extends StatefulWidget {
  const TwelveBarsPage({super.key});

  @override
  State<TwelveBarsPage> createState() => _TwelveBarsPageState();
}

class _TwelveBarsPageState extends State<TwelveBarsPage> {
  static const int totalBars = 12;
  static const Duration barDuration = Duration(minutes: 30); // ⏱️ Modifié

  final List<String> constraints = [
    "Boire cul-sec",
    "Interdit d'aller aux toilettes",
    "Boire avec la main gauche",
    "Faire une photo de groupe avec un inconnu",
    "Interdit de parler au serveur pour commander",
    "Boire la pinte avec une paille",
    "Ni OUI ni NON sinon une pichenette de tout le monde",
    "Interdit de rire sinon boire 3 gorgées dans le verre de quelqu'un",
    "Chacun doit faire un selfie avec le barman",
    "Ne boire qu'à 5mn, 10mn, 15mn et 20mn",
    "Ne pas utiliser les mains pour boire",
    "Faire semblant qu'on fête l'anniversaire de quelqu'un",
  ];

  List<String> usedConstraints = [];
  int barIndex = 0;
  DateTime? barStartTime;
  String currentConstraint = "";
  Timer? countdownTimer;
  Duration timeLeft = barDuration;
  bool started = false;
  bool fiveMinuteWarningSent = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadSession();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: initAndroid);
    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'twelve_bars_channel',
      'Twelve Bars',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Temps écoulé !',
      'Passez au prochain bar 🍻',
      details,
    );
  }

  Future<void> _showFiveMinuteNotification() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 1000); // 📳 vibration 1s
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'twelve_bars_channel_5min',
      'Twelve Bars - 5 minutes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      1,
      '⏳ Plus que 5 minutes !',
      'Il vous reste 5 minutes avant de changer de bar !',
      details,
    );
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      barIndex = prefs.getInt('barIndex') ?? 0;
      String? startString = prefs.getString('barStartTime');
      currentConstraint = prefs.getString('constraint') ?? "";
      usedConstraints = prefs.getStringList('usedConstraints') ?? [];
      if (startString != null) {
        barStartTime = DateTime.tryParse(startString);
        started = true;
      }
      if (barStartTime != null) {
        _startTimer();
      }
    });
  }

  void _startTimer() {
    countdownTimer?.cancel();
    fiveMinuteWarningSent = false;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(barStartTime!);
      final remaining = barDuration - elapsed;

      if (remaining <= const Duration(minutes: 5) && !fiveMinuteWarningSent) {
        _showFiveMinuteNotification();
        fiveMinuteWarningSent = true;
      }

      if (remaining <= Duration.zero) {
        setState(() {
          timeLeft = Duration.zero;
        });
        timer.cancel();
        _showNotification();
      } else {
        setState(() {
          timeLeft = remaining;
        });
      }
    });
  }

  String _generateConstraint() {
    final available = constraints.where((c) => !usedConstraints.contains(c)).toList();
    if (available.isEmpty) {
      usedConstraints.clear();
      return _generateConstraint();
    }
    final selected = available[Random().nextInt(available.length)];
    usedConstraints.add(selected);
    return selected;
  }

  Future<void> _startNewBar() async {
    if (barIndex >= totalBars) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final newConstraint = _generateConstraint();

    setState(() {
      barStartTime = now;
      timeLeft = barDuration;
      currentConstraint = newConstraint;
      started = true;
    });

    prefs.setInt('barIndex', barIndex);
    prefs.setString('barStartTime', now.toIso8601String());
    prefs.setString('constraint', newConstraint);
    prefs.setStringList('usedConstraints', usedConstraints);

    _startTimer();
  }

  Future<void> _goToNextBar() async {
    if (barIndex >= totalBars - 1) {
      setState(() {
        barIndex++;
      });
      return;
    }
    setState(() {
      barIndex++;
    });
    await _startNewBar();
  }

  Future<void> _resetSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('barIndex');
    await prefs.remove('barStartTime');
    await prefs.remove('constraint');
    await prefs.remove('usedConstraints');
    setState(() {
      barIndex = 0;
      barStartTime = null;
      timeLeft = barDuration;
      currentConstraint = "";
      started = false;
      usedConstraints.clear();
    });
    countdownTimer?.cancel();
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Réinitialiser l'activité ?"),
        content: const Text("Cela remettra le compteur à zéro et effacera la progression actuelle."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetSession();
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
        centerTitle: true,
        title: Text("Les 12 Bars", style: theme.titleMedium),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showResetConfirmationDialog(context),
        tooltip: "Réinitialiser l’activité",
        backgroundColor: Colors.white,
        child: const Icon(Icons.restart_alt),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: barIndex >= totalBars
              ? Text("🎉 Activité terminée ! Bravo !", style: theme.titleLarge)
              : !started
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Prêt à commencer ?", style: theme.titleLarge),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _startNewBar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("C’est parti !", style: theme.buttonText),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Bar ${barIndex + 1}/$totalBars", style: theme.titleLarge),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: 1 - (timeLeft.inSeconds / barDuration.inSeconds),
                          minHeight: 8,
                          backgroundColor: theme.textSecondary.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.secondary),
                        ),
                        const SizedBox(height: 16),
                        Text("⏳ Temps restant", style: theme.bodyMedium),
                        Text(_formatDuration(timeLeft), style: theme.titleLarge.copyWith(fontSize: 48)),
                        const SizedBox(height: 24),
                        Text("🎲 Contrainte", style: theme.bodyMedium),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.secondary, width: 1),
                          ),
                          child: Text(
                            currentConstraint,
                            style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _goToNextBar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("Passer au bar suivant", style: theme.buttonText),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
