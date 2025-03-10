import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  String? _gender;
  String? _photoUrl;
  bool _isUploading = false;

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
        final data = userDoc.data() as Map<String, dynamic>?;

        setState(() {
          _pseudoController.text = data?['pseudo'] ?? '';
          _nameController.text = data?['name'] ?? '';
          _surnameController.text = data?['surname'] ?? '';
          _gender = data?['gender'] ?? 'Autre';
          _photoUrl = data?['photoUrl'];
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      File imageFile = File(pickedFile.path);

      setState(() {
        _isUploading = true;
      });

      Reference ref = _storage.ref().child('profile_picture/${user.uid}.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        String newPhotoUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': newPhotoUrl,
        });

        setState(() {
          _photoUrl = newPhotoUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Photo de profil mise à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur lors de l'upload : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'upload : $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
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
          onPressed: () => Navigator.pop(context, _photoUrl != null),
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
                onTap: _pickAndUploadImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                        child: Image.network(
                          _photoUrl ??
                              "https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg",
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    if (_isUploading)
                      const CircularProgressIndicator(),

                    Positioned(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.edit, size: 30, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              _buildTextField(theme, 'Pseudo', _pseudoController),
              _buildTextField(theme, 'Nom', _nameController),
              _buildTextField(theme, 'Prénom', _surnameController),

              _buildDropdownField(theme, 'Genre', _gender, ['Homme', 'Femme', 'Autre']),

              const SizedBox(height: 100),

              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Enregistrer', style: theme.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(AppTheme theme, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdownField(AppTheme theme, String label, String? value, List<String> items, {double height = 60.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: height, // 🔹 Définir la hauteur
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Ajuste l'intérieur du champ
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: theme.bodyMedium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _gender = newValue;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
