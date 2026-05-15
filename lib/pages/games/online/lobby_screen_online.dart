import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';
import 'package:uuid/uuid.dart';

import 'lobby_waiting_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  final String gameName; // 🔹 Nom du jeu sélectionné

  const OnlineLobbyScreen({super.key, required this.gameName});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _lobbyCodeController = TextEditingController();

  bool _isProcessing = false; // 🔹 Empêche le multi-clic

  // 🔹 Table de correspondance entre les noms des jeux et leurs routes
  final Map<String, String> gameRoutes = {
    'Jeu du débat': Routes.debateGame,
  };

  /// 🔹 **Créer un lobby et générer un code**
  Future<void> _createLobby() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final User? user = _auth.currentUser;
    if (user == null) {
      setState(() => _isProcessing = false);
      return;
    }

    String lobbyId = const Uuid().v4().substring(0, 6).toUpperCase();
    String gameRoute =
        gameRoutes[widget.gameName] ?? '/homepage'; // 🔹 Route du jeu

    await _firestore.collection('lobbies').doc(lobbyId).set({
      'hostId': user.uid,
      'players': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'isStarted': false,
      'gameRoute': gameRoute, // 🔹 Stocker la route du jeu
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyWaitingScreen(
              lobbyId: lobbyId, isHost: true, gameRoute: gameRoute),
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  /// 🔹 **Rejoindre un lobby existant**
  Future<void> _joinLobby() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final User? user = _auth.currentUser;
    if (user == null) {
      setState(() => _isProcessing = false);
      return;
    }

    String lobbyId = _lobbyCodeController.text.trim().toUpperCase();
    if (lobbyId.isEmpty) {
      setState(() => _isProcessing = false);
      return;
    }

    DocumentSnapshot lobbyDoc =
        await _firestore.collection('lobbies').doc(lobbyId).get();
    if (!mounted) return;
    if (!lobbyDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lobby introuvable")),
      );
      setState(() => _isProcessing = false);
      return;
    }

    String gameRoute =
        lobbyDoc['gameRoute'] ?? '/homepage'; // 🔹 Récupérer la route du jeu

    await _firestore.collection('lobbies').doc(lobbyId).update({
      'players': FieldValue.arrayUnion([user.uid]),
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyWaitingScreen(
              lobbyId: lobbyId, isHost: false, gameRoute: gameRoute),
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: 'En ligne — ${widget.gameName}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CRÉER UN LOBBY',
                      style: theme.overline
                          .copyWith(color: theme.textMuted, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(
                    "Tu génères un code que tes potes utilisent pour rejoindre.",
                    style: theme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                    label: _isProcessing ? 'Création…' : 'Créer un lobby',
                    icon: Icons.add_rounded,
                    onPressed: _isProcessing ? null : _createLobby,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: theme.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OU', style: theme.overline),
                ),
                Expanded(child: Divider(color: theme.border)),
              ],
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REJOINDRE UN LOBBY',
                      style: theme.overline
                          .copyWith(color: theme.textMuted, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('Tape le code partagé par l\'hôte.',
                      style: theme.bodyMedium),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _lobbyCodeController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[a-zA-Z0-9]+$')),
                    ],
                    textAlign: TextAlign.center,
                    style: theme.titleMedium.copyWith(
                      letterSpacing: 6,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(hintText: 'CODE'),
                  ),
                  const SizedBox(height: 14),
                  GhostButton(
                    label: _isProcessing ? 'Connexion…' : 'Rejoindre',
                    icon: Icons.login_rounded,
                    onPressed: _isProcessing ? null : _joinLobby,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
