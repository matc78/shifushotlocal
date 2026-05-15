import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  final _pseudoController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();

  String? _gender;
  String? _photoUrl;
  bool _isUploading = false;

  static const _defaultPhoto =
      'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (!doc.exists) return;
    final data = doc.data();
    setState(() {
      _pseudoController.text = data?['pseudo'] ?? '';
      _nameController.text = data?['name'] ?? '';
      _surnameController.text = data?['surname'] ?? '';
      _gender = data?['gender'] ?? 'Autre';
      _photoUrl = data?['photoUrl'];
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      final imageFile = File(pickedFile.path);
      setState(() => _isUploading = true);

      final ref = _storage.ref().child('profile_picture/${user.uid}.jpg');
      final snapshot = await ref.putFile(imageFile);
      if (snapshot.state == TaskState.success) {
        final newUrl = await snapshot.ref.getDownloadURL();
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'photoUrl': newUrl});
        if (!mounted) return;
        setState(() => _photoUrl = newUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo mise à jour !'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur upload : $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return AppShell(
      title: 'Modifier le profil',
      onBack: () => Navigator.pop(context, _photoUrl != null),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: theme.brandGradient,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _photoUrl ?? _defaultPhoto,
                        width: 114,
                        height: 114,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_isUploading)
                    const SizedBox(
                      width: 120,
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.surface,
                        border: Border.all(color: theme.primary, width: 2),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.edit_rounded,
                          size: 18, color: theme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pseudoController,
              style: theme.bodyLarge,
              decoration: const InputDecoration(hintText: 'Pseudo'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: theme.bodyLarge,
                    decoration: const InputDecoration(hintText: 'Nom'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _surnameController,
                    style: theme.bodyLarge,
                    decoration: const InputDecoration(hintText: 'Prénom'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              dropdownColor: theme.surface,
              style: theme.bodyLarge,
              decoration: const InputDecoration(hintText: 'Genre'),
              items: const ['Homme', 'Femme', 'Autre']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Enregistrer',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}
