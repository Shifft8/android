import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const RegisterScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Создаём пользователя в Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Сохраняем профиль в Firestore
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Переход в MainNavigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildForm(BuildContext context, AppLocalizations loc) {
    final fields = [
      {'controller': _firstNameController, 'label': loc.firstName},
      {'controller': _lastNameController, 'label': loc.lastName},
      {'controller': _emailController, 'label': loc.email},
      {'controller': _passwordController, 'label': loc.password, 'obscure': true},
      {'controller': _phoneController, 'label': loc.phone},
      {'controller': _countryController, 'label': loc.country},
      {'controller': _cityController, 'label': loc.city},
    ];

    return Column(
      children: [
        for (var f in fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Platform.isIOS
                ? CupertinoTextField(
              controller: f['controller'] as TextEditingController,
              placeholder: f['label'] as String,
              obscureText: f['obscure'] == true,
            )
                : TextField(
              controller: f['controller'] as TextEditingController,
              decoration: InputDecoration(labelText: f['label'] as String),
              obscureText: f['obscure'] == true,
            ),
          ),
        const SizedBox(height: 20),
        if (_error != null)
          Text(_error!, style: TextStyle(color: Platform.isIOS ? CupertinoColors.systemRed : Colors.red)),
        const SizedBox(height: 20),
        _loading
            ? (Platform.isIOS ? const CupertinoActivityIndicator() : const CircularProgressIndicator())
            : (Platform.isIOS
            ? CupertinoButton.filled(child: Text(loc.register), onPressed: _register)
            : ElevatedButton(child: Text(loc.register), onPressed: _register)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(loc.register)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildForm(context, loc),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.register)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildForm(context, loc),
      ),
    );
  }
}
