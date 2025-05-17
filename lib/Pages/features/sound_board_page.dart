import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../../theme/app_theme.dart';

class SoundBoardPage extends StatefulWidget {
  final String categoryName;
  final List<String> sounds;

  const SoundBoardPage({
    required this.categoryName,
    required this.sounds,
    Key? key,
  }) : super(key: key);

  @override
  _SoundBoardPageState createState() => _SoundBoardPageState();
}

class _SoundBoardPageState extends State<SoundBoardPage> with SingleTickerProviderStateMixin {
  final AudioPlayer player = AudioPlayer();
  String? playing;
  bool isLocked = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _playSound(String path) async {
    if (isLocked) return;

    final relativePath = path.replaceFirst('assets/', '');
    setState(() {
      playing = path;
      isLocked = true;
    });

    _controller.forward();

    await player.play(AssetSource(relativePath));
    player.onPlayerComplete.listen((event) {
      _controller.stop();
      setState(() {
        playing = null;
        isLocked = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(widget.categoryName, style: theme.titleMedium),
        centerTitle: true,
        backgroundColor: theme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: widget.sounds.map((soundPath) {
          final label = soundPath.split('/').last.split('.').first;
          final isPlaying = playing == soundPath;

          final animatedCard = AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isPlaying ? _scaleAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isPlaying ? theme.secondary : theme.buttonColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.buttonText.copyWith(fontSize: 18),
                ),
              ),
            ),
          );

          return GestureDetector(
            onTap: () => _playSound(soundPath),
            child: AbsorbPointer(
              absorbing: isLocked && !isPlaying,
              child: animatedCard,
            ),
          );
        }).toList(),
      ),
    );
  }
}
