import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  String? _gender;
  String? _photoUrl;

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
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _pseudoController.text = data['pseudo'] ?? '';
          _nameController.text = data['name'] ?? '';
          _surnameController.text = data['surname'] ?? '';
          _birthdateController.text = data['birthdate'] != null
              ? DateFormat('dd/MM/yyyy').format(data['birthdate'].toDate())
              : '';
          _gender = data['gender'] ?? 'Autre';
          _photoUrl = data['photoUrl'];
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final birthdate = _birthdateController.text.isNotEmpty
          ? Timestamp.fromDate(
              DateFormat('dd/MM/yyyy').parse(_birthdateController.text),
            )
          : null;

      await _firestore.collection('users').doc(user.uid).update({
        'pseudo': _pseudoController.text,
        'name': _nameController.text,
        'surname': _surnameController.text,
        'birthdate': birthdate,
        'gender': _gender,
        'photoUrl': _photoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil mis à jour avec succès.',
            style: AppTheme.of(context).bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Retourner à la page précédente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la mise à jour : $e',
            style: AppTheme.of(context).bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
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
        title: Text('Modifier le profil', style: theme.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: theme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // Logic to upload or select a new profile picture
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(
                    _photoUrl ?? 'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
                  ),
                  child: const Icon(Icons.edit, size: 30, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(theme, 'Pseudo', _pseudoController),
              _buildTextField(theme, 'Nom', _nameController),
              _buildTextField(theme, 'Prénom', _surnameController),
              _buildDateField(theme),
              _buildGenderDropdown(theme),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Enregistrer', style: theme.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(AppTheme theme, String label,
      TextEditingController controller,
      {String? hintText, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _birthdateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () async {
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: _birthdateController.text.isNotEmpty
                ? DateFormat('dd/MM/yyyy').parse(_birthdateController.text)
                : DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            setState(() {
              _birthdateController.text =
                  DateFormat('dd/MM/yyyy').format(pickedDate);
            });
          }
        },
      ),
    );
  }

  Widget _buildGenderDropdown(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Genre', style: theme.bodyMedium),
          DropdownButton<String>(
            value: _gender,
            items: ['Homme', 'Femme', 'Autre'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: theme.bodyMedium),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _gender = newValue!;
              });
            },
            isExpanded: true,
            underline: Container(
              height: 1,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
