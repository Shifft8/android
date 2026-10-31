import 'dart:io' show Platform;

import 'package:address_manager/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  MainNavigation _mainNavigation() => MainNavigation(
        onLocaleChanged: widget.onLocaleChanged,
        onDarkModeChanged: widget.onDarkModeChanged,
        isDarkMode: widget.isDarkMode,
        currentLocale: widget.currentLocale,
      );

  Future<void> _register() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase did not return the created user.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        Platform.isIOS
            ? CupertinoPageRoute(builder: (_) => _mainNavigation())
            : MaterialPageRoute(builder: (_) => _mainNavigation()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildForm(AppLocalizations loc) {
    final fields = <({TextEditingController controller, String label, bool obscure})>[
      (controller: _firstNameController, label: loc.firstName, obscure: false),
      (controller: _lastNameController, label: loc.lastName, obscure: false),
      (controller: _emailController, label: loc.email, obscure: false),
      (controller: _passwordController, label: loc.password, obscure: true),
      (controller: _phoneController, label: loc.phone, obscure: false),
      (controller: _countryController, label: loc.country, obscure: false),
      (controller: _cityController, label: loc.city, obscure: false),
    ];

    return Column(
      children: [
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Platform.isIOS
                ? CupertinoTextField(
                    controller: field.controller,
                    placeholder: field.label,
                    obscureText: field.obscure,
                  )
                : TextField(
                    controller: field.controller,
                    decoration: InputDecoration(labelText: field.label),
                    obscureText: field.obscure,
                  ),
          ),
        const SizedBox(height: 12),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(
              color: Platform.isIOS ? CupertinoColors.systemRed : Colors.red,
            ),
          ),
        const SizedBox(height: 20),
        if (_loading)
          Platform.isIOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator()
        else if (Platform.isIOS)
          CupertinoButton.filled(
            onPressed: _register,
            child: Text(loc.register),
          )
        else
          ElevatedButton(
            onPressed: _register,
            child: Text(loc.register),
          ),
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
            child: _buildForm(loc),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.register)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _buildForm(loc),
          ),
        ),
      ),
    );
  }
}
