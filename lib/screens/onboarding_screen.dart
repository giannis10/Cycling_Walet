import 'package:flutter/material.dart';

import '../widgets/app_brand_icon.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinished,
    this.markCompletedOnFinish = true,
  });

  final VoidCallback onFinished;
  final bool markCompletedOnFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.directions_bike_rounded,
      useAppIcon: true,
      title: 'Καλώς ήρθες στο Cycling Wallet',
      body:
          'Η ψηφιακή θήκη για τις κάρτες ποδηλάτου σου: UCI, ΕΟΠ και '
          'Κάρτα Υγείας — πάντα στο κινητό, χωρίς χαρτιά.',
    ),
    _OnboardingSlide(
      icon: Icons.add_a_photo_rounded,
      title: 'Πώς βάζεις φωτογραφίες',
      steps: [
        'Άνοιξε την καρτέλα «Έγγραφα».',
        'Στην κάρτα που θέλεις, πάτα το πλαίσιο «Μπρος» ή «Πίσω».',
        'Διάλεξε «Κάμερα» για νέα φωτογραφία ή «Συλλογή» από τις υπάρχουσες.',
        'Μπορείς να έχεις έως 2 φωτογραφίες ανά κάρτα (μπροστινή & πίσω).',
      ],
    ),
    _OnboardingSlide(
      icon: Icons.zoom_in_rounded,
      title: 'Πώς βλέπεις τις κάρτες',
      steps: [
        'Πάτα πάνω στον τίτλο της κάρτας (π.χ. UCI) — όχι στα πλαίσια φωτο.',
        'Ανοίγει η προβολή σε πλήρη οθόνη με μεγέθυνση (pinch/zoom).',
        'Η φωτεινότητα ανεβαίνει αυτόματα για ευανάγνωστο έγγραφο.',
        'Αν έχεις 2 φωτο, σύρε αριστερά/δεξιά για να αλλάξεις πλευρά.',
      ],
    ),
    _OnboardingSlide(
      icon: Icons.credit_card_rounded,
      iconAsset: 'assets/icons/uci.png',
      title: 'Ημερομηνίες λήξης',
      steps: [
        'UCI: ψάχνουμε «Valid until» στη φωτογραφία.',
        'ΕΟΠ: ψάχνουμε «Ισχύει έως».',
        'Κάρτα υγείας: η ημερομηνία έκδοσης λήγει 1 χρόνο μετά.',
        'Στην εφαρμογή (Android/iOS) η ημερομηνία μπορεί να συμπληρωθεί αυτόματα μετά τη φωτο.',
      ],
    ),
    _OnboardingSlide(
      icon: Icons.notifications_active_rounded,
      title: 'Υπενθυμίσεις',
      steps: [
        'Άνοιξε την καρτέλα «Υπενθυμίσεις».',
        'Πάτα «Ορισμός» για να βάλεις ή να αλλάξεις την ημερομηνία λήξης.',
        'Χρησιμοποίησε το switch για να ενεργοποιείς/κλείνεις ειδοποίηση ανά κάρτα.',
        '«Ανάγνωση» σκανάρει την ημερομηνία από τη φωτο (μόνο στην εγκατεστημένη εφαρμογή).',
        '«Ημερολόγιο» προσθέτει υπενθύμιση λήξης στο ημερολόγιο του κινητού.',
      ],
    ),
    _OnboardingSlide(
      icon: Icons.settings_rounded,
      title: 'Ρυθμίσεις',
      steps: [
        '«Ειδοποιήσεις»: γενικό on/off για όλη την εφαρμογή.',
        '«Μέρες υπενθύμισης»: πόσες μέρες πριν τη λήξη (προεπιλογή 30).',
        '«Αντίστροφη μέτρηση»: εμφάνιση «Λήγει σε X μέρες» αντί για ημερομηνία.',
        '«Οδηγός εφαρμογής»: μπορείς να ξαναδείς αυτό το tutorial όποτε θέλεις.',
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onFinished,
                child: Text(
                  _page < _slides.length - 1 ? 'Παράλειψη' : 'Κλείσιμο',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  return _SlidePage(slide: _slides[index]);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final active = index == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page < _slides.length - 1 ? 'Επόμενο' : 'Ξεκίνα',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    this.body,
    this.steps,
    this.iconAsset,
    this.useAppIcon = false,
  });

  final IconData icon;
  final String? iconAsset;
  final bool useAppIcon;
  final String title;
  final String? body;
  final List<String>? steps;
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          if (slide.useAppIcon)
            const AppBrandIcon()
          else
            _SlideIcon(slide: slide),
          const SizedBox(height: 24),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (slide.body != null)
            Text(
              slide.body!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          if (slide.steps != null) _TutorialSteps(steps: slide.steps!),
        ],
      ),
    );
  }
}

class _SlideIcon extends StatelessWidget {
  const _SlideIcon({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: slide.iconAsset != null
          ? Image.asset(
              slide.iconAsset!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Icon(
                slide.icon,
                size: 44,
                color: Colors.white,
              ),
            )
          : Icon(slide.icon, size: 44, color: Colors.white),
    );
  }
}

class _TutorialSteps extends StatelessWidget {
  const _TutorialSteps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  steps[index],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
