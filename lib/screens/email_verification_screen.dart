import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;
  final String? initialMessage;
  const EmailVerificationScreen({super.key, required this.user, this.initialMessage});

  static final Map<String, DateTime> _lastSent = {};
  static void recordEmailSent(String uid) => _lastSent[uid] = DateTime.now();

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _busy = false;
  String? _message;

  // shortcut: local translations; move to ARB when extending verification copy.
  String _text(String key) {
    const copy = {
      'ru': ['Подтвердите email', 'Я подтвердил почту', 'Отправить письмо повторно',
        'Письмо отправлено. Проверьте почту и папку «Спам».', 'Почта ещё не подтверждена.',
        'Нет соединения. Проверьте сеть и повторите попытку.',
        'Слишком много запросов. Подождите и попробуйте снова.',
        'Сессия недействительна. Выйдите и войдите снова.',
        'Не удалось выполнить запрос. Попробуйте ещё раз.'],
      'en': ['Verify your email', 'I have verified my email', 'Resend email',
        'Email sent. Check your inbox and spam folder.', 'Your email is not verified yet.',
        'Connection failed. Check your network and try again.',
        'Too many requests. Please wait and try again.',
        'Your session is invalid. Sign out and sign in again.',
        'The request failed. Please try again.'],
      'pl': ['Potwierdź email', 'Potwierdziłem email', 'Wyślij ponownie',
        'Wiadomość wysłana. Sprawdź skrzynkę i spam.', 'Email nie jest jeszcze potwierdzony.',
        'Brak połączenia. Sprawdź sieć i spróbuj ponownie.',
        'Zbyt wiele żądań. Poczekaj i spróbuj ponownie.',
        'Sesja jest nieważna. Wyloguj się i zaloguj ponownie.',
        'Żądanie nie powiodło się. Spróbuj ponownie.'],
      'uk': ['Підтвердьте email', 'Я підтвердив пошту', 'Надіслати лист повторно',
        'Лист надіслано. Перевірте пошту та спам.', 'Пошту ще не підтверджено.',
        'Немає з’єднання. Перевірте мережу та спробуйте знову.',
        'Забагато запитів. Зачекайте та спробуйте знову.',
        'Сесія недійсна. Вийдіть та увійдіть знову.',
        'Не вдалося виконати запит. Спробуйте ще раз.'],
    };
    const keys = ['title', 'check', 'resend', 'sent', 'pending', 'network', 'limit', 'session', 'error'];
    return (copy[Localizations.localeOf(context).languageCode] ?? copy['en']!)[keys.indexOf(key)];
  }

  int get _secondsLeft {
    final sent = EmailVerificationScreen._lastSent[widget.user.uid];
    if (sent == null) return 0;
    return (60 - DateTime.now().difference(sent).inSeconds).clamp(0, 60);
  }

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(String action) async {
    if (_busy || (action == 'resend' && _secondsLeft > 0)) return;
    setState(() { _busy = true; _message = null; });
    try {
      if (action == 'logout') {
        await FirebaseAuth.instance.signOut();
      } else if (action == 'resend') {
        // Throttle attempts too, including network failures.
        EmailVerificationScreen.recordEmailSent(widget.user.uid);
        await widget.user.sendEmailVerification();
        if (mounted) setState(() => _message = _text('sent'));
      } else {
        await widget.user.reload();
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.uid != widget.user.uid) return;
        if (user.emailVerified) {
          await user.getIdToken(true);
        } else if (mounted) {
          setState(() => _message = _text('pending'));
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final key = switch (error.code) {
        'network-request-failed' => 'network',
        'too-many-requests' => 'limit',
        'user-disabled' || 'user-not-found' || 'user-token-expired' || 'invalid-user-token' => 'session',
        _ => 'error',
      };
      setState(() => _message = _text(key));
    } catch (_) {
      if (mounted) setState(() => _message = _text('error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_text('title')), automaticallyImplyLeading: false),
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.mark_email_unread_outlined, size: 64),
          const SizedBox(height: 24),
          Text(widget.user.email ?? '', textAlign: TextAlign.center),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          if (_busy) const CircularProgressIndicator(),
          ElevatedButton(onPressed: _busy ? null : () => _run('check'), child: Text(_text('check'))),
          TextButton(
            onPressed: _busy || _secondsLeft > 0 ? null : () => _run('resend'),
            child: Text('${_text('resend')}${_secondsLeft > 0 ? ' ($_secondsLeft)' : ''}'),
          ),
          TextButton(onPressed: _busy ? null : () => _run('logout'),
            child: Text(AppLocalizations.of(context)!.logoutButton)),
        ]),
      )),
    );
  }
}
