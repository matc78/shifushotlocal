import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:dice_icons/dice_icons.dart';
import 'package:shifushotlocal/app_theme.dart';

class DiceGamePage extends StatefulWidget {
  final List<String> players;
  final List<String> remainingGames;

  const DiceGamePage({
    Key? key,
    required this.players,
    required this.remainingGames,
  }) : super(key: key);

  @override
  _DiceGamePageState createState() => _DiceGamePageState();
}

class _DiceGamePageState extends State<DiceGamePage> {
  int dice1 = 1;
  int dice2 = 1;
  bool isRolling = false;
  String resultMessage = '';

  final Map<String, String> rules = {
    '1_1': '\nDonner un FU',
    '2_2': '\nDonner 2 SHI',
    '3_3': '\nDonner un surnom,\nSe mettre en couple,\nDonner 3 SHI',
    '4_4': '\nDouble prison\nThème ou mini-jeux',
    '5_5': '\nDonner 5 SHI',
    '6_6': '\nInventer une règle\nDonner 6 SHI',
    '1_2': '\nPas de règle',
    '1_3': '\nPas de règle',
    '1_4': '\nPrison\nJeu du clap',
    '1_5': '\nDonner un surnom\nSe mettre en couple',
    '1_6': '\nBizkit !',
    '2_4': '\nPrison\nDonner un surnom\nSe mettre en couple',
    '2_6': '\nThème ou mini-jeux',
    '3_6': '\nJeu du doigt',
    '4_6': '\nPrison',
    '5_6': '\nInventer une règle\nDonner une règle',
    '2_3': '\nJeu du clap',
    '3_4': '\nPrison\nBizkit !',
    '4_5': '\nPrison\nJeu du doigt',
    '3_5': '\nThème ou mini-jeux',
    '2_5': '\nBizkit !',
  };

  final List<Map<String, String>> temporaryRules = []; // Règles temporaires

  @override
  void dispose() {
    // Effacer toutes les règles temporaires à la sortie de la page
    temporaryRules.clear();
    super.dispose();
  }

  void _addTemporaryRule(String key, String rule) {
    setState(() {
      if (rules.containsKey(key)) {
        rules[key] = '${rules[key]!}$rule';
      } else {
        rules[key] = '\n$rule';
      }
      temporaryRules.add({key: rule}); // Stocker temporairement
    });
  }

  void _showTemporaryRules() {
  final theme = AppTheme.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Règles temporaires', style: theme.titleMedium),
      backgroundColor: theme.background,
      content: temporaryRules.isEmpty
          ? Center(
              child: Text(
                'Aucune règle temporaire ajoutée.',
                style: theme.bodyMedium,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: temporaryRules.map((entry) {
                final combination = entry.keys.first.split('_');
                final ruleDescription = entry.values.first;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '• combinaison ${combination[0]} et ${combination[1]} : $ruleDescription',
                    textAlign: TextAlign.center,
                    style: theme.bodyLarge,
                  ),
                );
              }).toList(),
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Fermer', style: theme.bodyMedium),
        ),
      ],
    ),
  );
}

Future<void> _handleInventRule() async {
  final theme = AppTheme.of(context);
  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Inventer une règle', style: theme.titleMedium),
      backgroundColor: theme.background,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addRuleForSpecificNumber();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
            child: Text(
              'Règle temporaire pour un résultat spécifique',
              textAlign: TextAlign.center,
              style: theme.buttonText,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addGeneralRule();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
            child: Text(
              'Règle temporaire générale',
              textAlign: TextAlign.center,
              style: theme.buttonText,
            ),
          ),
          const SizedBox(height: 10),
          if (temporaryRules.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeTemporaryRule();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
              child: Text(
                'Supprimer une règle ajoutée',
                textAlign: TextAlign.center,
                style: theme.buttonText,
              ),
            ),
        ],
      ),
    ),
  );
}

void _removeTemporaryRule() {
  final theme = AppTheme.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Supprimer une règle temporaire', style: theme.titleMedium),
      backgroundColor: theme.background,
      content: temporaryRules.isEmpty
          ? Center(
              child: Text(
                'Aucune règle temporaire à supprimer.',
                style: theme.bodyMedium,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: temporaryRules.map((entry) {
                final key = entry.keys.first;
                final combination = key.split('_');
                final ruleDescription = entry.values.first;
                return ListTile(
                  title: Text(
                    '• combinaison ${combination[0]} et ${combination[1]} : $ruleDescription',
                    textAlign: TextAlign.center,
                    style: theme.bodyLarge,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        temporaryRules.remove(entry);
                        rules[key] = rules[key]!.replaceAll('\n$ruleDescription', '');
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }).toList(),
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Fermer', style: theme.bodyMedium),
        ),
      ],
    ),
  );
}

void _addRuleForSpecificNumber() {
  final theme = AppTheme.of(context);
  int? selectedDie1;
  int? selectedDie2;
  final TextEditingController ruleController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Ajouter une règle pour un nombre spécifique', style: theme.titleMedium),
      backgroundColor: theme.background,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choisissez une combinaison de dés\n(par ex. 1 et 6, '
            'Cela s\'appliquera également pour 6 et 1.)',
            style: theme.bodyMedium.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: selectedDie1,
            items: List.generate(
              6,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}', style: theme.bodyMedium),
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedDie1 = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Premier dé',
              labelStyle: theme.bodyMedium,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: selectedDie2,
            items: List.generate(
              6,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}', style: theme.bodyMedium),
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedDie2 = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Deuxième dé',
              labelStyle: theme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ruleController,
            decoration: InputDecoration(
              labelText: 'Description de la règle',
              labelStyle: theme.bodyMedium,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (selectedDie1 != null &&
                selectedDie2 != null &&
                ruleController.text.trim().isNotEmpty) {
              final String key = selectedDie1! <= selectedDie2!
                  ? '${selectedDie1!}_${selectedDie2!}'
                  : '${selectedDie2!}_${selectedDie1!}';
              _addTemporaryRule(key, '\n${ruleController.text.trim()}');
              Navigator.of(context).pop();
            }
          },
          child: Text('Ajouter', style: theme.bodyMedium),
        ),
      ],
    ),
  );
}

void _addGeneralRule() {
  final theme = AppTheme.of(context);
  final TextEditingController ruleController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Ajouter une règle temporaire générale', style: theme.titleMedium),
      backgroundColor: theme.background,
      content: TextField(
        controller: ruleController,
        decoration: InputDecoration(
          labelText: 'Description de la règle',
          labelStyle: theme.bodyMedium,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (ruleController.text.trim().isNotEmpty) {
              temporaryRules.add({'Générale': '\n${ruleController.text.trim()}'});
              Navigator.of(context).pop();
            }
          },
          child: Text('Ajouter', style: theme.bodyMedium),
        ),
      ],
    ),
  );
}

  void rollDice() {
  setState(() {
    isRolling = true;
  });

  int animationSteps = 15; // Nombre de frames pour l'animation (1.5 secondes à raison de ~10 changements par seconde)

  void animateDice(int step) {
    if (step < animationSteps) {
      setState(() {
        // Affichage aléatoire pendant l'animation
        dice1 = Random().nextInt(6) + 1; // Générer un chiffre aléatoire entre 1 et 6
        dice2 = Random().nextInt(6) + 1;
      });

      // Continuer l'animation avec un intervalle de 100 ms
      Timer(const Duration(milliseconds: 100), () => animateDice(step + 1));
    } else {
      // Animation terminée, afficher les vraies valeurs
      setState(() {
        dice1 = Random().nextInt(6) + 1; // Générer le résultat final pour le premier dé
        dice2 = Random().nextInt(6) + 1; // Générer le résultat final pour le deuxième dé

        final String key = dice1 <= dice2 ? '${dice1}_${dice2}' : '${dice2}_${dice1}';

        if (rules.containsKey(key)) {
          if (rules[key]!.contains('Inventer une règle')) {
            _handleInventRule();
          }
          resultMessage = rules[key]!;
        } else {
          resultMessage = 'Aucune règle trouvée';
        }

        isRolling = false;
      });
    }
  }

  // Lancer l'animation
  animateDice(0);
}



  void _showRulesExplanation() {
    final theme = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Explications des règles de base', style: theme.titleMedium),
        backgroundColor: theme.background,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: theme.bodyMedium,
                  children: const [
                    TextSpan(text: 'Double 1 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' Donner un FU\n\n'),
                    TextSpan(text: 'Tous les doubles :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' Donner le nombre de SHI correspondant\n\n'),
                    TextSpan(text: '11 et 12 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' Inventer une règle\n\n'),
                    TextSpan(text: 'Si un 4 dans la combinaison :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text:
                          ' Le premier joueur ayant lancé un 4 devient prisonnier et doit boire une SHI à chaque fois qu’un 4 est lancé par un autre joueur.\n'
                          'Il ne peut y avoir qu’un seul prisonnier et pour sortir, il faut qu’il fasse un autre 4.\n\n',
                    ),
                    TextSpan(text: 'Double 4 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text:
                          ' Si quelqu’un est en prison alors il boit double. Si personne, alors il entre et ressort de prison donc personne en prison.\n\n',
                    ),
                    TextSpan(text: '8 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text:
                          ' Le lanceur peut inventer un thème. Chaque joueur doit dire un mot en rapport avec le thème tour à tour sans se répéter. '
                          'Ou il peut inventer un mini-jeu et décider de ses règles.\n\n',
                    ),
                    TextSpan(text: '9 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text:
                          ' Le jeu du doigt. Chaque joueur doit mettre son doigt sur une bouteille, et chacun son tour, ils diront : 1, 2, 3... un chiffre qu’ils pensent être '
                          'le nombre de doigts restant sur la bouteille.\n'
                          'Si un joueur devine le bon nombre, il peut enlever son doigt. Cela continue jusqu’au dernier joueur restant qui devra prendre un FU.\n\n',
                    ),
                    TextSpan(text: '7 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text:
                          ' Le dernier qui dira "Bizkit !" avec le pouce sur le front devra prendre 5 SHI.\n\n',
                    ),
                    TextSpan(text: '5 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text:
                          ' Jeu du clap. On commence par le lanceur des dés et dans le sens des aiguilles d’une montre.\n'
                          'Chaque joueur aura 3 possibilités :\n'
                          '1 clap pour passer au prochain joueur dans le même sens,\n'
                          '2 claps pour changer de sens,\n'
                          '3 claps pour passer le prochain joueur en gardant le sens.\n'
                          '3 SHI pour celui qui se trompe.\n\n',
                    ),
                    TextSpan(text: '6 :', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text:
                          ' Donner un surnom à un joueur. Tout le monde devra l’appeler par ce surnom sinon celui qui se trompe prend 1 SHI.\n'
                          'Se mettre en couple avec un joueur et donc boire tout pareil que lui. Il ne peut y avoir qu’un seul couple, donc le couple s’arrête au prochain 6.\n',
                    ),
                  ],
                ),
              ),
            ],

          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Fermer', style: theme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _endGame() {
  if (widget.remainingGames.isNotEmpty && widget.remainingGames.first != '/homepage') {
    // Jeux restants : passer au jeu suivant automatiquement
    Navigator.pushNamed(
      context,
      widget.remainingGames.first,
      arguments: {
        'players': widget.players,
        'remainingGames': widget.remainingGames.sublist(1),
      },
    );
  } else {
    // Plus de jeux (ou uniquement /homepage) : afficher un bouton pour terminer
    showDialog(
      context: context,
      builder: (context) {
        final theme = AppTheme.of(context);
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text(
            "Fin de la partie",
            style: theme.titleMedium,
          ),
          content: Text(
            "Voulez-vous terminer le jeu et revenir à l'accueil ?",
            style: theme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text(
                "Terminer",
                style: theme.buttonText.copyWith(color: theme.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: Text(
                "Annuler",
                style: theme.buttonText.copyWith(color: theme.secondary),
              ),
            ),
          ],
        );
      },
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bizkit !', style: theme.titleMedium),
        backgroundColor: theme.background,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: theme.primary),
            onPressed: () {
              _showRulesExplanation();
            },
          ),
        ],
      ),
      backgroundColor: theme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Icon(
                        isRolling ? _getDiceIcon(Random().nextInt(6) + 1) : _getDiceIcon(dice1),
                        size: 200,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Icon(
                        isRolling ? _getDiceIcon(Random().nextInt(6) + 1) : _getDiceIcon(dice2),
                        size: 200,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: isRolling ? null : rollDice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isRolling ? 'Lancement...' : 'Lancer les dés',
                  style: theme.buttonText.copyWith(fontSize: 30),
                ),
              ),
              const SizedBox(height: 30),
              if (resultMessage.isNotEmpty)
                Text(
                  'Règle(s) :$resultMessage',
                  textAlign: TextAlign.center,
                  style: theme.bodyLarge.copyWith(fontSize: 18),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _showTemporaryRules,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Voir les règles temporaires',
                  style: theme.buttonText,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: widget.remainingGames.isEmpty || widget.remainingGames.first == '/homepage'
                    ? () {
                        // Retour à l'accueil
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    : () {
                        // Passer au jeu suivant
                        Navigator.pushNamed(
                          context,
                          widget.remainingGames.first,
                          arguments: {
                            'players': widget.players,
                            'remainingGames': widget.remainingGames.sublist(1),
                          },
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.remainingGames.isEmpty || widget.remainingGames.first == '/homepage'
                      ? 'Retour à l\'accueil'
                      : 'Passer au jeu suivant',
                  style: theme.buttonText.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  IconData _getDiceIcon(int diceValue) {
    switch (diceValue) {
      case 1:
        return DiceIcons.dice1;
      case 2:
        return DiceIcons.dice2;
      case 3:
        return DiceIcons.dice3;
      case 4:
        return DiceIcons.dice4;
      case 5:
        return DiceIcons.dice5;
      case 6:
        return DiceIcons.dice6;
      default:
        return DiceIcons.dice0;
    }
  }
}