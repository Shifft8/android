import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'main_navigation.dart';

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

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController(text: 'Poland');

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Пожалуйста, заполните Email и Пароль");
      return;
    }

    if (password.length < 6) {
      setState(() => _error = "Пароль должен быть не менее 6 символов");
      return;
    }

    if (_isSignUp && (name.isEmpty || phone.isEmpty || city.isEmpty || country.isEmpty)) {
      setState(() => _error = "Пожалуйста, заполните все поля регистрации");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;

        if (user != null) {
          await user.updateDisplayName(name);
          await user.sendEmailVerification();

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': name,
            'phone': phone,
            'city': city,
            'country': country,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

          await Future.delayed(const Duration(seconds: 1));
          await FirebaseAuth.instance.signOut();
        }

        setState(() {
          _error = "Аккаунт успешно создан! На вашу почту отправлено письмо. Пожалуйста, подтвердите её и войдите.";
          _isSignUp = false;
        });
        return;
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          await userCredential.user!.sendEmailVerification();
          await FirebaseAuth.instance.signOut();
          setState(() {
            _error = AppLocalizations.of(context)!.errorAuth;
          });
          return;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _error = "Неверный email или пароль";
        } else if (e.code == 'email-already-in-use') {
          _error = "Этот email уже зарегистрирован";
        } else {
          _error = e.message;
        }
      });
    } catch (e) {
      setState(() => _error = "Что-то пошло не так: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final String primaryButtonText = _isSignUp ? "Зарегистрироваться" : loc.login;
    final String toggleButtonText = _isSignUp ? "Уже есть аккаунт? Войти" : "Ещё нет аккаунта? Создать";
    final String screenTitle = _isSignUp ? "Регистрация" : loc.login;

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onDarkModeChanged(!widget.isDarkMode),
          ),
          TextButton(
            child: Text(
              widget.currentLocale.languageCode.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            onPressed: () {
              Locale newLocale = widget.currentLocale.languageCode == 'ru'
                  ? const Locale('en')
                  : const Locale('ru');
              widget.onLocaleChanged(newLocale);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isSignUp) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, size: 70, color: Colors.blue),
                ),
                const SizedBox(height: 32),
              ],

              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Имя и фамилия',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Телефон',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Город',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _countryController,
                  decoration: InputDecoration(
                    labelText: 'Страна',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: loc.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: loc.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _submit,
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _error = null;
                  });
                },
                child: Text(
                  toggleButtonText,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}