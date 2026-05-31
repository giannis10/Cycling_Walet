import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'tour_tooltip_card.dart';

/// GlobalKeys για στοχευμένα στοιχεία του feature tour.
class AppFeatureTourKeys {
  AppFeatureTourKeys();

  final GlobalKey navDocuments = GlobalKey();
  final GlobalKey cardPhotos = GlobalKey();
  final GlobalKey cardView = GlobalKey();
  final GlobalKey navReminders = GlobalKey();
  final GlobalKey reminderDateButton = GlobalKey();
  final GlobalKey reminderSwitch = GlobalKey();
  final GlobalKey navSettings = GlobalKey();
  final GlobalKey settingsNotifications = GlobalKey();

  GlobalKey? keyFor(String identify) {
    switch (identify) {
      case 'nav_documents':
        return navDocuments;
      case 'card_photos':
        return cardPhotos;
      case 'card_view':
        return cardView;
      case 'nav_reminders':
        return navReminders;
      case 'reminder_date':
        return reminderDateButton;
      case 'reminder_switch':
        return reminderSwitch;
      case 'nav_settings':
        return navSettings;
      case 'settings_notifications':
        return settingsNotifications;
      default:
        return null;
    }
  }

  static int tabIndexFor(String identify) {
    switch (identify) {
      case 'reminder_date':
      case 'reminder_switch':
      case 'nav_settings':
        return 1;
      case 'settings_notifications':
        return 2;
      default:
        return 0;
    }
  }
}

typedef TourStepPreparer = Future<void> Function(String identify);

class AppFeatureTour {
  AppFeatureTour._();

  static const int stepCount = 8;

  static Future<void> show({
    required BuildContext context,
    required AppFeatureTourKeys keys,
    required TourStepPreparer onPrepareStep,
    VoidCallback? onFinished,
    VoidCallback? onSkipped,
  }) async {
    final targets = _buildTargets(
      keys: keys,
      onPrepareStep: onPrepareStep,
    );

    await onPrepareStep('nav_documents');

    final coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.82,
      paddingFocus: 10,
      alignSkip: Alignment.topRight,
      textSkip: '',
      hideSkip: true,
      pulseEnable: true,
      onClickTarget: (target) async {
        final id = target.identify.toString();
        await onPrepareStep(id);
      },
      onFinish: onFinished,
      onSkip: () {
        onSkipped?.call();
        return true;
      },
    );

    coach.show(context: context);
  }

  static List<TargetFocus> _buildTargets({
    required AppFeatureTourKeys keys,
    required TourStepPreparer onPrepareStep,
  }) {
    TargetFocus focus({
      required String id,
      required GlobalKey key,
      required int step,
      required String text,
      required ContentAlign align,
      bool isLast = false,
    }) {
      return TargetFocus(
        identify: id,
        keyTarget: key,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: align,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            builder: (context, controller) {
              return TourTooltipCard(
                text: text,
                stepIndex: step,
                stepCount: stepCount,
                nextLabel: isLast ? 'Τέλος' : 'Επόμενο',
                onSkip: () => controller.skip(),
                onNext: () async {
                  final nextId = _nextStepId(step);
                  if (nextId != null) {
                    await onPrepareStep(nextId);
                  }
                  controller.next();
                },
              );
            },
          ),
        ],
      );
    }

    return [
      focus(
        id: 'nav_documents',
        key: keys.navDocuments,
        step: 0,
        align: ContentAlign.top,
        text:
            'Χρησιμοποίησε το κάτω μενού για να μετακινηθείς. '
            'Εδώ είναι τα έγγραφά σου (UCI, ΕΟΠ, Κάρτα Υγείας).',
      ),
      focus(
        id: 'card_photos',
        key: keys.cardPhotos,
        step: 1,
        align: ContentAlign.bottom,
        text:
            'Πάτα «Μπρος» ή «Πίσω» για να βάλεις φωτογραφία από κάμερα '
            'ή συλλογή (έως 2 φωτο ανά κάρτα).',
      ),
      focus(
        id: 'card_view',
        key: keys.cardView,
        step: 2,
        align: ContentAlign.bottom,
        text:
            'Πάτα στον τίτλο της κάρτας για προβολή σε πλήρη οθόνη με zoom. '
            'Η φωτεινότητα ανεβαίνει αυτόματα.',
      ),
      focus(
        id: 'nav_reminders',
        key: keys.navReminders,
        step: 3,
        align: ContentAlign.top,
        text: 'Στις «Υπενθυμίσεις» ορίζεις λήξη και ειδοποιήσεις ανά κάρτα.',
      ),
      focus(
        id: 'reminder_date',
        key: keys.reminderDateButton,
        step: 4,
        align: ContentAlign.bottom,
        text:
            'Πάτα «Ορισμός» για να βάλεις την ημερομηνία λήξης. '
            'Με φωτογραφία μπορεί να συμπληρωθεί αυτόματα (εφαρμογή Android/iOS).',
      ),
      focus(
        id: 'reminder_switch',
        key: keys.reminderSwitch,
        step: 5,
        align: ContentAlign.bottom,
        text:
            'Ενεργοποίησε ή κλείσε τις ειδοποιήσεις μόνο για αυτή την κάρτα '
            '(π.χ. UCI off, ΕΟΠ on).',
      ),
      focus(
        id: 'nav_settings',
        key: keys.navSettings,
        step: 6,
        align: ContentAlign.top,
        text: 'Στις «Ρυθμίσεις» ελέγχεις ειδοποιήσεις και εμφάνιση λήξης.',
      ),
      focus(
        id: 'settings_notifications',
        key: keys.settingsNotifications,
        step: 7,
        align: ContentAlign.top,
        isLast: true,
        text:
            'Άνοιξε τις ειδοποιήσεις, όρισε μέρες πριν τη λήξη (προεπιλογή 30) '
            'και την αντίστροφη μέτρηση «Λήγει σε X μέρες».',
      ),
    ];
  }

  static const _stepOrder = [
    'nav_documents',
    'card_photos',
    'card_view',
    'nav_reminders',
    'reminder_date',
    'reminder_switch',
    'nav_settings',
    'settings_notifications',
  ];

  static String? _nextStepId(int currentStep) {
    final next = currentStep + 1;
    if (next >= _stepOrder.length) {
      return null;
    }
    return _stepOrder[next];
  }
}
