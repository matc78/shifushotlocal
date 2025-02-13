import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Pour restreindre les entrées du code lobby
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'lobby_waiting_screen.dart'; // Page d'attente du lobby

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({Key? key}) : super(key: key);

  @override
  _OnlineLobbyScreenState createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _lobbyCodeController = TextEditingController();

  bool _isProcessing = false; // 🔹 Empêche le multi-clic

  /// 🔹 **Créer un lobby et générer un code**
  Future<void> _createLobby() async {
    if (_isProcessing) return; // 🔹 Empêche de cliquer plusieurs fois
    setState(() => _isProcessing = true);

    final User? user = _auth.currentUser;
    if (user == null) {
      setState(() => _isProcessing = false);
      return;
    }

    String lobbyId = const Uuid().v4().substring(0, 6).toUpperCase();

    await _firestore.collection('lobbies').doc(lobbyId).set({
      'hostId': user.uid,
      'players': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'isStarted': false,
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyWaitingScreen(lobbyId: lobbyId, isHost: true),
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  /// 🔹 **Rejoindre un lobby existant**
  Future<void> _joinLobby() async {
    if (_isProcessing) return; // 🔹 Empêche de cliquer plusieurs fois
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

    DocumentSnapshot lobbyDoc = await _firestore.collection('lobbies').doc(lobbyId).get();
    if (!lobbyDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lobby introuvable")),
      );
      setState(() => _isProcessing = false);
      return;
    }

    await _firestore.collection('lobbies').doc(lobbyId).update({
      'players': FieldValue.arrayUnion([user.uid]),
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyWaitingScreen(lobbyId: lobbyId, isHost: false),
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Jeu en Ligne", style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// **Section Création du Lobby**
              Text("Créer un Lobby", style: theme.titleMedium),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isProcessing ? null : _createLobby, // Désactive le bouton si en traitement
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white) // Affiche un loader
                    : Text("Créer un Lobby", style: theme.buttonText),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              const SizedBox(height: 20),

              /// **Section Rejoindre un Lobby**
              Text("Rejoindre un Lobby", style: theme.titleMedium),
              const SizedBox(height: 10),
              TextField(
                controller: _lobbyCodeController,
                textCapitalization: TextCapitalization.characters, // 🔹 Convertit en majuscules
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9]+$')), // 🔹 Accepte que lettres et chiffres
                ],
                decoration: InputDecoration(
                  labelText: "Entrer un Code Lobby",
                  labelStyle: theme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.textSecondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primary),
                  ),
                ),
                textAlign: TextAlign.center,
                style: theme.bodyLarge,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isProcessing ? null : _joinLobby, // Désactive le bouton si en traitement
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white) // Affiche un loader
                    : Text("Rejoindre", style: theme.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
