import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';
import 'package:vibration/vibration.dart';

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
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'twelve_bars_channel',
      'Twelve Bars',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'twelve_bars_channel_5min',
      'Twelve Bars - 5 minutes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
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
    final available =
        constraints.where((c) => !usedConstraints.contains(c)).toList();
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
        content: const Text(
            "Cela remettra le compteur à zéro et effacera la progression actuelle."),
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

    return AppShell(
      title: 'Les 12 Bars',
      actions: started
          ? [
              IconButton(
                icon: Icon(Icons.restart_alt_rounded, color: theme.textPrimary),
                tooltip: 'Réinitialiser',
                onPressed: () => _showResetConfirmationDialog(context),
              ),
            ]
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: barIndex >= totalBars
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎉',
                        style: theme.displayLarge.copyWith(fontSize: 80)),
                    const SizedBox(height: 16),
                    Text('Activité terminée !',
                        style: theme.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Bravo aux survivants.', style: theme.bodyMedium),
                  ],
                ),
              )
            : !started
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('LES 12 BARS',
                            style: theme.overline
                                .copyWith(color: theme.textMuted)),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (rect) =>
                              theme.brandGradient.createShader(rect),
                          child: Text('Prêt ?',
                              style: theme.displayLarge
                                  .copyWith(color: Colors.white, fontSize: 56)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '12 bars × 30 minutes. Une contrainte tirée au sort à chaque bar.',
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        GradientButton(
                          label: "C'est parti !",
                          icon: Icons.sports_bar_rounded,
                          onPressed: _startNewBar,
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      SectionCard(
                        child: Column(
                          children: [
                            Text('BAR ${barIndex + 1} / $totalBars',
                                style: theme.overline.copyWith(
                                  color: theme.textMuted,
                                  letterSpacing: 2,
                                )),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: 1 -
                                    (timeLeft.inSeconds /
                                        barDuration.inSeconds),
                                minHeight: 10,
                                backgroundColor: theme.surfaceAlt,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.primary),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (rect) =>
                                  theme.brandGradient.createShader(rect),
                              child: Text(_formatDuration(timeLeft),
                                  style: theme.displayLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 56,
                                  )),
                            ),
                            Text('TEMPS RESTANT',
                                style: theme.overline
                                    .copyWith(color: theme.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CONTRAINTE',
                                style: theme.overline.copyWith(
                                  color: theme.textMuted,
                                  letterSpacing: 2,
                                )),
                            const SizedBox(height: 8),
                            Text(currentConstraint,
                                style: theme.bodyLarge.copyWith(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                )),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GradientButton(
                        label: 'Passer au bar suivant',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _goToNextBar,
                      ),
                    ],
                  ),
      ),
    );
  }
}
