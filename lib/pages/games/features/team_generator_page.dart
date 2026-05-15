import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class TeamGeneratorPage extends StatefulWidget {
  const TeamGeneratorPage({super.key});

  @override
  State<TeamGeneratorPage> createState() => _TeamGeneratorPageState();
}

class _TeamGeneratorPageState extends State<TeamGeneratorPage> {
  final List<String> _names = [];
  final TextEditingController _nameController = TextEditingController();
  int _peoplePerTeam = 2;
  final Map<int, List<String>> _teams = {};
  String? _warning;

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserSurname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _names.add('Moi'));
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final surname = userDoc.data()?['surname'] as String? ?? 'Moi';
      setState(() => _names.add(surname));
    } catch (e) {
      debugPrint('TeamGenerator: surname fetch failed — $e');
      if (mounted) setState(() => _names.add('Moi'));
    }
  }

  void _addName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _names.add(name);
      _nameController.clear();
    });
  }

  void _generateTeams() {
    if (_names.length < _peoplePerTeam) {
      setState(() => _warning =
          'Ajoute plus de personnes pour des équipes de $_peoplePerTeam.');
      return;
    }
    setState(() {
      _warning = null;
      _teams.clear();
      final shuffled = List<String>.from(_names)..shuffle();
      final totalTeams = (shuffled.length / _peoplePerTeam).ceil();
      for (var i = 0; i < totalTeams; i++) {
        final size = shuffled.length < _peoplePerTeam
            ? shuffled.length
            : _peoplePerTeam;
        _teams[i] = shuffled.take(size).toList();
        shuffled.removeRange(0, size);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: "Créateur d'équipes",
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: theme.bodyLarge,
                    decoration: const InputDecoration(hintText: 'Prénom'),
                    onSubmitted: (_) => _addName(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: GradientButton(
                    label: 'Ajouter',
                    onPressed: _addName,
                    expanded: false,
                    height: 52,
                  ),
                ),
              ],
            ),
            if (_warning != null) ...[
              const SizedBox(height: 10),
              Text(_warning!,
                  style: theme.bodyMedium.copyWith(color: theme.primary)),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _names.isEmpty
                  ? const EmptyState(
                      icon: Icons.group_outlined,
                      title: 'Personne pour l\'instant',
                      subtitle: 'Ajoute des prénoms pour générer des équipes.',
                    )
                  : ListView.separated(
                      itemCount: _names.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final name = _names[i];
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
                                      setState(() => _names.removeAt(i)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Text('Par équipe :', style: theme.bodyMedium),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _peoplePerTeam,
                  dropdownColor: theme.surface,
                  style: theme.bodyLarge,
                  underline: const SizedBox.shrink(),
                  items: const [1, 2, 3]
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) => setState(() => _peoplePerTeam = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Générer les équipes',
              icon: Icons.shuffle_rounded,
              onPressed: _generateTeams,
            ),
            if (_teams.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final team = _teams[i]!;
                    return SectionCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: theme.brandGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: theme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Équipe ${i + 1}',
                                    style: theme.overline),
                                const SizedBox(height: 2),
                                Text(team.join(' & '),
                                    style: theme.bodyLarge.copyWith(
                                      color: theme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
