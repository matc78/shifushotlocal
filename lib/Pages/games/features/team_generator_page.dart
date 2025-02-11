import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';

class TeamGeneratorPage extends StatefulWidget {
  const TeamGeneratorPage({Key? key}) : super(key: key);

  @override
  State<TeamGeneratorPage> createState() => _TeamGeneratorPageState();
}

class _TeamGeneratorPageState extends State<TeamGeneratorPage> {
  final List<String> names = [];
  final TextEditingController nameController = TextEditingController();
  int peoplePerTeam = 2;
  Map<int, List<String>> teams = {};
  String? warningMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  Future<void> _fetchUserSurname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final surname = userDoc.data()?['surname'] ?? "Moi";
          setState(() {
            names.add(surname);
          });
        } else {
          setState(() {
            names.add("Moi");
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération du surname : $e');
      }
    }
  }

  void generateTeams() {
    if (names.length < peoplePerTeam) {
      setState(() {
        warningMessage =
            "Ajoutez plus de personnes pour créer des équipes de $peoplePerTeam.";
      });
      return;
    }

    setState(() {
      warningMessage = null;
      teams.clear();
      final shuffledNames = List<String>.from(names)..shuffle();
      final int totalTeams = (shuffledNames.length / peoplePerTeam).ceil();

      for (int i = 0; i < totalTeams; i++) {
        int teamSize = peoplePerTeam;

        if (shuffledNames.length < teamSize) {
          teamSize = shuffledNames.length;
        }

        teams[i] = shuffledNames.take(teamSize).toList();
        shuffledNames.removeRange(0, teamSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créateur d\'équipes',
          style: theme.titleMedium,
        ),
        backgroundColor: theme.background,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: theme.textPrimary,
        ),
        elevation: 0,
      ),
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Ajouter un prénom',
                      labelStyle: theme.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.textSecondary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primary,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.background,
                    ),
                    style: theme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        names.add(nameController.text.trim());
                        nameController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    'Ajouter',
                    style: theme.buttonText,
                  ),
                ),
              ],
            ),
            if (warningMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  warningMessage!,
                  style: theme.bodyMedium.copyWith(color: theme.secondary),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: names.length,
                itemBuilder: (context, index) {
                  final name = names[index];
                  final isCurrentUser = index == 0;

                  return ListTile(
                    title: Text(name),
                    trailing: isCurrentUser
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                names.removeAt(index);
                              });
                            },
                          ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Text(
                  'Personnes par équipe :',
                  style: theme.bodyMedium,
                ),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: peoplePerTeam,
                  items: List.generate(3, (index) => index + 1)
                      .map((value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      peoplePerTeam = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: generateTeams,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Générer les équipes',
                style: theme.buttonText,
              ),
            ),
            const SizedBox(height: 20),
            if (teams.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index]!;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(team.join(' & ')),
                        subtitle: Text('Équipe ${index + 1}'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
