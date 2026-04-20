import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/pwa_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  PwaService.instance.init();
  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cycling Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black, foregroundColor: Colors.white),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _skipLanding = false;

  bool get _shouldShowLanding {
    final pwa = PwaService.instance;
    return !pwa.isInstalled && !_skipLanding;
  }

  void _continueWithoutInstall() {
    setState(() => _skipLanding = true);
  }

  Future<void> _handleInstall(BuildContext context) async {
    final pwa = PwaService.instance;
    if (pwa.canInstall) {
      final ok = await pwa.promptInstall();
      if (ok) {
        setState(() => _skipLanding = true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Η εγκατάσταση ακυρώθηκε.')),
      );
      return;
    }

    if (!mounted) return;
    if (pwa.isIos) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Εγκατάσταση εφαρμογής'),
          content: const Text('Σε iPhone: πάτησε Share → Add to Home Screen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Εγκατάσταση εφαρμογής'),
        content: const Text(
          'Σε Android/desktop: άνοιξε το μενού του browser και επίλεξε '
          '"Install app" ή "Add to desktop".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowLanding) {
      return const HomeScreen();
    }
    return _LandingScreen(
      onInstall: () => _handleInstall(context),
      onContinue: _continueWithoutInstall,
    );
  }
}

class _LandingScreen extends StatelessWidget {
  const _LandingScreen({
    required this.onInstall,
    required this.onContinue,
  });

  final VoidCallback onInstall;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Transform.scale(
                    scale: 1.25,
                    child: Image.asset(
                      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.directions_bike_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cycling Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Εγκατέστησε την εφαρμογή για γρήγορη πρόσβαση\n'
                'ή συνέχισε απευθείας από τον browser.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onInstall,
                  child: const Text('Εγκατάσταση'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onContinue,
                child: const Text('Χρήση χωρίς εγκατάσταση'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
