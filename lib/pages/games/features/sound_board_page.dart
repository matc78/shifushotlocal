import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class SoundBoardPage extends StatefulWidget {
  const SoundBoardPage({
    required this.categoryName,
    required this.sounds,
    super.key,
  });

  final String categoryName;
  final List<String> sounds;

  @override
  State<SoundBoardPage> createState() => _SoundBoardPageState();
}

class _SoundBoardPageState extends State<SoundBoardPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  String? _playing;
  bool _isLocked = false;

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
    if (_isLocked) return;
    final relative = path.replaceFirst('assets/', '');
    setState(() {
      _playing = path;
      _isLocked = true;
    });
    _controller.forward();
    await _player.play(AssetSource(relative));
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _controller.stop();
      setState(() {
        _playing = null;
        _isLocked = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: widget.categoryName,
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: widget.sounds.map((path) {
          final label = path.split('/').last.split('.').first;
          final isPlaying = _playing == path;
          return GestureDetector(
            onTap: () => _playSound(path),
            child: AbsorbPointer(
              absorbing: _isLocked && !isPlaying,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: isPlaying ? _scaleAnimation.value : 1.0,
                  child: child,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isPlaying ? theme.brandGradient : null,
                    color: isPlaying ? null : theme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                        color: isPlaying ? theme.primary : theme.border),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
