import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/state/app_scope.dart';
import '../../core/utils/image_url.dart';
import '../../shared/ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _imageController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  Uint8List? _profileImageBytes;
  String? _profileImageName;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _imageController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _profileImageBytes = bytes;
          _profileImageName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil fotoğrafı seçilemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Önce giriş yapın.')));
    }

    if (!_loaded) {
      _loaded = true;
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phoneNumber;
      _bioController.text = user.bio;
      _imageController.text = user.profileImageUrl;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassPanel(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Ad Soyad'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Zorunlu alan'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Hakkımda'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageController,
                      decoration:
                          const InputDecoration(labelText: 'Profil Resim URL'),
                    ),
                    const SizedBox(height: 12),
                    if (_profileImageBytes != null ||
                        _imageController.text.trim().isNotEmpty)
                      Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : NetworkImage(
                                  resolveImageUrl(controller.api.baseUrl,
                                      _imageController.text),
                                ) as ImageProvider,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _saving
                              ? null
                              : () => _pickProfileImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeriden Seç'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _pickProfileImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Fotoğraf Çek'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Şifre değiştir',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Mevcut Şifre'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Yeni Şifre'),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _saving = true);
                                try {
                                  var profileImageUrl =
                                      _imageController.text.trim();
                                  if (_profileImageBytes != null &&
                                      _profileImageName != null) {
                                    profileImageUrl =
                                        await controller.api.uploadImage(
                                      bytes: _profileImageBytes!,
                                      fileName: _profileImageName!,
                                      category: 'profiles',
                                    );
                                  }
                                  await controller.api.updateProfile(
                                    fullName: _fullNameController.text.trim(),
                                    phoneNumber: _phoneController.text.trim(),
                                    bio: _bioController.text.trim(),
                                    profileImageUrl: profileImageUrl,
                                    currentPassword: _currentPasswordController
                                            .text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : _currentPasswordController.text,
                                    newPassword: _newPasswordController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : _newPasswordController.text,
                                  );
                                  await controller.refreshSession();
                                  if (mounted) Navigator.of(context).pop();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _saving = false);
                                }
                              },
                        child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
