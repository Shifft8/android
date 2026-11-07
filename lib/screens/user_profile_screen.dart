import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'edit_profile_screen.dart';


class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userCountry = 'Poland';
  String _userCity = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _currentUser;
    if (user == null) return;

    setState(() {
      _userEmail = user.email ?? '';
      _userName = user.displayName ?? 'Новый пользователь';
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? _userName;
          _userPhone = data['phone'] ?? '';
          _userCity = data['city'] ?? '';
          _userCountry = data['country'] ?? 'Poland';
          _userEmail = data['email'] ?? _userEmail;
        });
      }
    } catch (e) {
      print("Ошибка загрузки профиля: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Обновленный метод сохранения всех полей
  Future<void> _saveProfileToFirestore(String name, String phone, String city,
      String country, String email) async {
    final user = _currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Если пользователь поменял email, обновляем его в Firebase Auth
      if (email != user.email && email.isNotEmpty) {
        await user.updateEmail(email);
      }

      // 2. Обновляем имя в профиле Auth
      await user.updateDisplayName(name);

      // 3. Сохраняем расширенные данные в Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'phone': phone,
        'city': city,
        'country': country,
        'email': email,
      }, SetOptions(merge: true));

      setState(() {
        _userName = name;
        _userPhone = phone;
        _userCity = city;
        _userCountry = country;
        _userEmail = email;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    final loc = AppLocalizations.of(context)!;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(loc.logoutButton),
          content: Text(loc.logoutButton),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(loc.cancel)),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(loc.logoutButton)),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await FirebaseAuth.instance.signOut();
      // RootScreen replaces the navigator and removes all user routes.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error}: $error')),
      );
    } finally {
      _loggingOut = false;
    }
  }
  // Обновленное окно редактирования со всеми полями
  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: _userName);
    final phoneController = TextEditingController(text: _userPhone);
    final cityController = TextEditingController(text: _userCity);
    final countryController = TextEditingController(text: _userCountry);
    final emailController = TextEditingController(text: _userEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;

        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
            bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations.editProfile,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations.firstName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: localizations.email,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: localizations.phone,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: localizations.city,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countryController,
                  decoration: InputDecoration(
                    labelText: localizations.country,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.flag),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text
                        .trim()
                        .isNotEmpty &&
                        emailController.text
                            .trim()
                            .isNotEmpty) {
                      await _saveProfileToFirestore(
                        nameController.text.trim(),
                        phoneController.text.trim(),
                        cityController.text.trim(),
                        countryController.text.trim(),
                        emailController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            // Используем 'added', который точно есть в твоем ARB
                            content: Text(localizations.added),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          // Используем 'error', который точно есть в твоем ARB
                          content: Text(localizations.error),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    localizations.save,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Получаем экземпляр локализации в самом начале сборки экрана
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          localizations.profile,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: const Icon(Icons.person, size: 55, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    _userEmail,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileRow(
                    Icons.phone_android,
                    localizations.phone,
                    _userPhone.isEmpty ? '—' : _userPhone,
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildProfileRow(
                    Icons.flag_outlined,
                    localizations.country,
                    _userCountry,
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildProfileRow(
                    Icons.location_city,
                    localizations.city,
                    _userCity.isEmpty ? '—' : _userCity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditProfileSheet,
                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                label: Text(
                  localizations.editProfile,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: Text(
                  localizations.logoutButton,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}