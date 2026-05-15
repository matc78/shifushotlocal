import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shifushotlocal/pages/profile/edit_profile_page.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/routes.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) { // Vérifie si le widget est monté
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    if (updated == true) {
      _fetchUserData(); // 🔄 Rafraîchir les données utilisateur immédiatement après mise à jour
    }
  }

  String _formatGameName(String rawKey) {
    // Tu peux personnaliser ça selon le nom utilisé dans Firestore
    switch (rawKey) {
      case 'clicker_game':
        return 'Le Clicker';
      case 'dice_game':
        return 'Bizkit !';
      case 'paper_game':
        return 'Jeu des papiers';
      case 'clock_game':
        return 'L\'Horloge';
      default:
        return rawKey.replaceAll('_', ' ').capitalize();
    }
  }




  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<bool> _reauthenticate(User user) async {
    final providerIds = user.providerData.map((p) => p.providerId).toList();

    if (providerIds.contains('google.com')) {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    }

    if (providerIds.contains('password')) {
      final passwordController = TextEditingController();
      final theme = AppTheme.of(context);
      final password = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Confirme ton mot de passe', style: theme.titleMedium),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, passwordController.text),
              child: const Text('Valider'),
            ),
          ],
        ),
      );
      if (password == null || password.isEmpty) return false;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    }
    return false;
  }

  Future<void> _deleteSubcollection(DocumentReference userRef, String name) async {
    final snap = await userRef.collection(name).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteAccount() async {
    final theme = AppTheme.of(context);
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression', style: theme.titleMedium),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? Toutes vos données seront effacées définitivement.',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: theme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: theme.bodyMedium.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmation != true) return;
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final uid = user.uid;
    final userRef = _firestore.collection('users').doc(uid);

    try {
      // 1. Nettoyer les sous-collections de l'utilisateur
      await _deleteSubcollection(userRef, 'shifushot_notifs');
      await _deleteSubcollection(userRef, 'shifushot_notifs_received');

      // 2. Retirer l'utilisateur des listes d'amis des autres utilisateurs (best-effort)
      final friendsSnap = await _firestore
          .collection('users')
          .where('friends', arrayContains: uid)
          .get();
      for (final doc in friendsSnap.docs) {
        await doc.reference.update({
          'friends': FieldValue.arrayRemove([uid]),
        });
      }

      // 3. Supprimer la photo de profil si elle existe sur Storage
      try {
        await FirebaseStorage.instance
            .ref()
            .child('profile_picture/$uid.jpg')
            .delete();
      } catch (_) {
        // pas de photo, on ignore
      }

      // 4. Supprimer le document utilisateur Firestore
      await userRef.delete();

      // 5. Supprimer le compte Firebase Auth (avec réauthentification si nécessaire)
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          final ok = await _reauthenticate(user);
          if (!ok) {
            messenger.showSnackBar(const SnackBar(
              content: Text('Réauthentification annulée. Le compte n\'a pas été supprimé.'),
              backgroundColor: Colors.orange,
            ));
            return;
          }
          await user.delete();
        } else {
          rethrow;
        }
      }

      // 6. Se déconnecter de Google si applicable
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      navigator.pushNamedAndRemoveUntil(Routes.debut, (route) => false);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erreur lors de la suppression du compte : $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context); // Utilisation de votre thème personnalisé

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: theme.textPrimary),
            onPressed: _navigateToEditProfile, // 🔹 Appelle la nouvelle fonction
          ),
        ],
      ),
      backgroundColor: theme.background,
      body: userData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        userData!['photoUrl'] ??
                            'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData!['pseudo'] ?? '',
                      style: theme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    _buildProfileField(theme, 'Email', userData!['email']),
                    _buildProfileField(theme, 'Nom', userData!['surname'] ?? ''),
                    _buildProfileField(theme, 'Prénom', userData!['name'] ?? ''),
                    _buildProfileField(
                        theme,
                        'Genre',
                        userData!['gender'] ?? 'Non spécifié', // Affiche une valeur par défaut
                      ),
                    _buildProfileField(
                      theme,
                      'Date d\'inscription',
                      userData!['createdAt'] != null
                          ? DateFormat('dd/MM/yyyy').format(userData!['createdAt'].toDate())
                          : '',
                    ),
                    const Divider(height: 32),
                    if (userData!['high_scores'] != null && userData!['high_scores'] is Map) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🏆 Mes stats et records',
                          style: theme.titleMedium.copyWith(fontSize: 22),
                        ),
                      ),

                      // 🔹 Section Scores par jeu
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🎮 Jeux',
                          style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...userData!['high_scores'].entries.map<Widget>((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatGameName(entry.key),
                                style: theme.bodyMedium,
                              ),
                              Text(
                                entry.value.toString(),
                                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // 🔹 Section Amis harcelés
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '📤 ShiFuShot envoyés',
                          style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('shifushot_notifs')
                            .orderBy('count', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) return const SizedBox();

                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final pseudo = data['name'] ?? 'Inconnu';
                              final count = data['count'] ?? 0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(pseudo, style: theme.bodyMedium),
                                    Text(
                                      '$count demandes',
                                      style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      // 🔹 Section Amis qui te harcèlent le plus
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '📥 ShiFuShot reçus',
                          style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('shifushot_notifs_received') // ← à adapter si besoin
                            .orderBy('count', descending: true)
                            .limit(3)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            return Text("Va chercher des potes", style: theme.bodyMedium);
                          }

                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Inconnu';
                              final count = data['count'] ?? 0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name, style: theme.bodyMedium),
                                    Text('$count demandes', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const Divider(height: 32),
                    ],
                    ListTile(
                      title: Text('Les notifs', style: theme.bodyMedium),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const CircularProgressIndicator();

                                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                final notif = (data['notifications'] as Map<String, dynamic>? ?? {});
                                bool global = notif['enabled'] ?? false;
                                bool friendRequests = notif['friend_requests'] ?? false;
                                bool shifushotRequests = notif['shifushot_requests'] ?? false;

                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    Future<void> updateNotif(String key, bool value) async {
                                      final uid = FirebaseAuth.instance.currentUser!.uid;
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .update({'notifications.$key': value});
                                    }

                                    Future<void> toggleAll(bool value) async {
                                      setState(() {
                                        global = value;
                                        friendRequests = value;
                                        shifushotRequests = value;
                                      });
                                      final uid = FirebaseAuth.instance.currentUser!.uid;
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .update({
                                        'notifications.enabled': value,
                                        'notifications.friend_requests': value,
                                        'notifications.shifushot_requests': value,
                                      });
                                    }

                                    Future<void> toggleOne(String key, bool value) async {
                                      setState(() {
                                        if (key == 'friend_requests') friendRequests = value;
                                        if (key == 'shifushot_requests') shifushotRequests = value;
                                      });

                                      await updateNotif(key, value);

                                      // Synchronise le switch global automatiquement
                                      final allEnabled = [friendRequests, shifushotRequests].every((v) => v == true);
                                      await updateNotif('enabled', allEnabled);
                                      setState(() => global = allEnabled);
                                    }

                                    return AlertDialog(
                                      title: const Text("Préférences de notification"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("🔔 Toutes les notifications"),
                                              Switch(
                                                value: global,
                                                onChanged: (value) => toggleAll(value),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("👥 Demandes d'amis"),
                                              Switch(
                                                value: friendRequests,
                                                onChanged: (value) => toggleOne('friend_requests', value),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("🥤 Invitations Shifushot"),
                                              Switch(
                                                value: shifushotRequests,
                                                onChanged: (value) => toggleOne('shifushot_requests', value),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Fermer"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const Divider(height: 32),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Se déconnecter',
                        style: theme.buttonText,
                      ),
                    ),
                    const SizedBox(height: 16), // Espacement entre les boutons
                    ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Supprimer le compte',
                        style: theme.buttonText.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileField(AppTheme theme, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: theme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

