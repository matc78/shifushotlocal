import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  List<dynamic> currentUserFriends = [];
  List<dynamic> currentUserFriendRequests = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentUserData();
    searchUsers('');
  }

  Future<void> fetchCurrentUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    setState(() {
      currentUserFriends = userDoc.data()?['friends'] ?? [];
      currentUserFriendRequests = userDoc.data()?['friend_requests'] ?? [];
    });
  }

  Future<void> searchUsers(String query) async {
    setState(() {
      isLoading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    QuerySnapshot querySnapshot;

    if (query.isEmpty) {
      // Récupérer tous les utilisateurs, exclure l'utilisateur connecté
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
          .get();
    } else {
      // Rechercher les utilisateurs correspondant au pseudo saisi
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('pseudo', isGreaterThanOrEqualTo: query)
          .where('pseudo', isLessThanOrEqualTo: '$query\uf8ff')
          .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
          .get();
    }

    setState(() {
      searchResults = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      isLoading = false;
    });
  }


  Future<void> sendFriendRequest(String friendUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Ajouter l'ID de l'utilisateur connecté dans `pending_approval` du user recherché
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .update({
        'pending_approval': FieldValue.arrayUnion([currentUser.uid]),
      });

      // Ajouter l'ID de l'utilisateur recherché dans `friend_requests` du current user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'friend_requests': FieldValue.arrayUnion([friendUid]),
      });

      // Afficher un SnackBar avec texte blanc
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black, // Couleur de fond
          content: Text(
            'Demande d\'ami envoyée.',
            style: AppTheme.of(context).bodyMedium.copyWith(
                  color: Colors.white, // Texte blanc
                ),
          ),
        ),
      );

      // Actualiser les données locales et l'interface utilisateur
      await fetchCurrentUserData();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red, // Couleur de fond pour erreur
          content: Text(
            'Erreur lors de l\'envoi : $e',
            style: AppTheme.of(context).bodyMedium.copyWith(
                  color: Colors.white, // Texte blanc
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text(
          'Ajouter des amis',
          style: theme.titleMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Barre de recherche
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un utilisateur par pseudo...',
                    prefixIcon: Icon(Icons.search, color: theme.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (value) {
                    searchUsers(value);
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Résultat de la recherche
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun utilisateur trouvé.',
                              style: theme.bodyMedium
                                  .copyWith(color: theme.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: searchResults.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = searchResults[index];
                              final friendUid = user['id'];

                              // Déterminer l'état du bouton
                              late String buttonText;
                              late Color buttonColor;

                              if (currentUserFriends.contains(friendUid)) {
                                buttonText = 'Ami';
                                buttonColor = Colors.green;
                              } else if (currentUserFriendRequests
                                  .contains(friendUid)) {
                                buttonText = 'En attente';
                                buttonColor = Colors.orange;
                              } else {
                                buttonText = 'Ajouter';
                                buttonColor = theme.buttonColor;
                              }

                              return Material(
                                elevation: 2,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      user['photoUrl'] ??
                                          'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
                                    ),
                                  ),
                                  title: Text(
                                    '${user['surname']} ${user['name']}',
                                    style: theme.bodyLarge,
                                  ),
                                  subtitle: Text(
                                    user['pseudo'] ?? '',
                                    style: theme.bodyMedium,
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: (buttonText == 'Ajouter')
                                        ? () => sendFriendRequest(friendUid)
                                        : () {}, // Les autres boutons ne font rien
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: buttonColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      buttonText,
                                      style: theme.buttonText,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
