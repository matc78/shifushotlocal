import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

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

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
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
            onPressed: () => Navigator.pushNamed(context, '/editProfile'),
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
                    _buildProfileField(theme, 'Nom', userData!['name'] ?? ''),
                    _buildProfileField(
                        theme, 'Prénom', userData!['surname'] ?? ''),
                    _buildProfileField(
                        theme,
                        'Genre',
                        userData!['gender'] ?? 'Non spécifié', // Affiche une valeur par défaut
                      ),
                    _buildProfileField(
                      theme,
                      'Anniversaire',
                      userData!['birthdate'] != null
                          ? (userData!['birthdate'] is Timestamp // Vérifie si c'est un Timestamp
                              ? DateFormat('dd/MM/yyyy').format(userData!['birthdate'].toDate())
                              : userData!['birthdate'] // Si ce n'est pas un Timestamp, affiche tel quel
                            )
                          : 'Non spécifié', // Valeur par défaut si null
                    ),
                    _buildProfileField(
                      theme,
                      'Date d\'inscription',
                      userData!['createdAt'] != null
                          ? DateFormat('dd/MM/yyyy').format(userData!['createdAt'].toDate())
                          : '',
                    ),
                    const Divider(height: 32),
                    ListTile(
                      title: Text('Mes stats et records',
                          style: theme.bodyMedium),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => Navigator.pushNamed(context, '/stats'),
                    ),
                    ListTile(
                      title: Text('Les notifs', style: theme.bodyMedium),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
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
