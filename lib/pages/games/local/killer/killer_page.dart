import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class KillerPage extends StatefulWidget {
  const KillerPage({super.key});

  @override
  State<KillerPage> createState() => _KillerPageState();
}

class _KillerPageState extends State<KillerPage> {
  final List<String> _players = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserSurname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _players.add('Moi'));
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final surname = doc.data()?['surname'] as String? ?? 'Moi';
      setState(() => _players.add(surname));
    } catch (e) {
      debugPrint('Killer: surname fetch failed — $e');
      if (mounted) setState(() => _players.add('Moi'));
    }
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _players.add(name);
      _controller.clear();
    });
  }

  void _startGame() {
    if (_players.length < 4) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Il faut au moins 4 joueurs.'),
        ));
      return;
    }
    Navigator.pushNamed(context, Routes.killerActions, arguments: _players);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: 'Killer',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: theme.bodyLarge,
                    decoration:
                        const InputDecoration(hintText: 'Ajouter un joueur'),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: GradientButton(
                    label: 'Ajouter',
                    onPressed: _addPlayer,
                    expanded: false,
                    height: 52,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _players.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_outline,
                      title: 'Aucun joueur',
                      subtitle:
                          'Ajoute au moins 4 joueurs pour démarrer une partie.',
                    )
                  : ListView.separated(
                      itemCount: _players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final name = _players[i];
                        final isCurrentUser = i == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: theme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: theme.brandGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: theme.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(name, style: theme.bodyLarge),
                              ),
                              if (!isCurrentUser)
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: theme.textMuted),
                                  onPressed: () =>
                                      setState(() => _players.removeAt(i)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Commencer la partie',
              icon: Icons.local_fire_department_rounded,
              onPressed: _startGame,
            ),
          ],
        ),
      ),
    );
  }
}
