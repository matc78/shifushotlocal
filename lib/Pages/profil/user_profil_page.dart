import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

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
                    const SizedBox(height: 16), // Espacement entre les boutons
                    ElevatedButton(
                      onPressed: () async {
                        final confirmation = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Confirmer la suppression', style: theme.titleMedium),
                            content: Text(
                              'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.',
                              style: theme.bodyMedium,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false), // Annuler
                                child: Text('Annuler', style: theme.bodyMedium),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true), // Confirmer
                                child: Text(
                                  'Supprimer',
                                  style: theme.bodyMedium.copyWith(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmation == true) {
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Supprimer les données utilisateur de Firestore
                              await _firestore.collection('users').doc(user.uid).delete();

                              // Supprimer l'utilisateur de Firebase Auth
                              await user.delete();

                              // Rediriger vers la page de connexion après suppression
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/connexion', // Assurez-vous que cette route existe dans votre application
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur lors de la suppression du compte : $e',
                                  style: theme.bodyMedium,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
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
