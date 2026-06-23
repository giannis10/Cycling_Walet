import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'widgets/app_brand_icon.dart';
import 'services/app_preferences_service.dart';
import 'services/notification_service.dart';
import 'services/pwa_service.dart';

/// Κύριο σημείο εκκίνησης της εφαρμογής.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Αρχικοποίηση βασικών υπηρεσιών
  await NotificationService.instance.initialize();
  await AppPreferencesService.instance.initialize();
  PwaService.instance.init();
  
  runApp(const WalletApp());
}

/// Βασική κλάση της εφαρμογής (Root Widget).
class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cycling Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // Παγκόσμιο φόντο εφαρμογής (Gradient)
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1E293B), Colors.black],
              radius: 1.2,
              center: Alignment.center,
            ),
          ),
          child: child,
        );
      },
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Η εγκατάσταση ακυρώθηκε.')),
      );
      return;
    }

    if (!context.mounted) return;
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
    if (_shouldShowLanding) {
      return _LandingScreen(
        onInstall: () => _handleInstall(context),
        onContinue: _continueWithoutInstall,
      );
    }
    return const HomeScreen();
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppBrandIcon(),
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
