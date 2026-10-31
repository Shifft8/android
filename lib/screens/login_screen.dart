import 'dart:io' show Platform;

import 'package:address_manager/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final void Function(bool) onDarkModeChanged;
  final bool isDarkMode;
  final Locale currentLocale;

  const LoginScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onDarkModeChanged,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        Platform.isIOS
            ? CupertinoPageRoute(
                builder: (_) => _mainNavigation(),
              )
            : MaterialPageRoute(
                builder: (_) => _mainNavigation(),
              ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.errorLogin);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  MainNavigation _mainNavigation() => MainNavigation(
        onLocaleChanged: widget.onLocaleChanged,
        onDarkModeChanged: widget.onDarkModeChanged,
        isDarkMode: widget.isDarkMode,
        currentLocale: widget.currentLocale,
      );

  void _openRegister() {
    final page = RegisterScreen(
      onLocaleChanged: widget.onLocaleChanged,
      onDarkModeChanged: widget.onDarkModeChanged,
      isDarkMode: widget.isDarkMode,
      currentLocale: widget.currentLocale,
    );
    Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (_) => page)
          : MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final fields = Column(
      children: [
        if (Platform.isIOS)
          CupertinoTextField(
            controller: _emailController,
            placeholder: loc.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          )
        else
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: loc.email),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
        const SizedBox(height: 12),
        if (Platform.isIOS)
          CupertinoTextField(
            controller: _passwordController,
            placeholder: loc.password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          )
        else
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: loc.password),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              color: Platform.isIOS ? CupertinoColors.systemRed : Colors.red,
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (_loading)
          Platform.isIOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator()
        else if (Platform.isIOS)
          CupertinoButton.filled(
            onPressed: _login,
            child: Text(loc.login),
          )
        else
          ElevatedButton(
            onPressed: _login,
            child: Text(loc.login),
          ),
        const SizedBox(height: 8),
        if (Platform.isIOS)
          CupertinoButton(
            onPressed: _loading ? null : _openRegister,
            child: Text(loc.register),
          )
        else
          TextButton(
            onPressed: _loading ? null : _openRegister,
            child: Text(loc.register),
          ),
      ],
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(loc.login)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(child: fields),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.login)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: fields,
        )),
      ),
    );
  }
}
