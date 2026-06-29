import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/document.dart';
import '../models/document_card_kind.dart';
import '../services/app_preferences_service.dart';

class WidgetService {
  WidgetService._();

  static final WidgetService instance = WidgetService._();

  /// Updates the Android widget with the latest document data
  Future<void> updateWidget(List<UserDocument> documents) async {
    if (kIsWeb) return;

    try {
      // 1. Convert documents to JSON array representation for Android
      // We pass each property as a delimited string so Kotlin can parse it easily,
      // or we pass just the top 3 cards explicitly since the widget only shows 3.

      final topDocs = documents.take(3).toList();
      
      for (int i = 0; i < 3; i++) {
        if (i < topDocs.length) {
          final doc = topDocs[i];
          final expiryStr = doc.expiresAt?.toIso8601String() ?? '';
          
          final kind = documentCardKindFromTitle(doc.title);
          final iconType = kind.name; // uci, eop, health, other

          await HomeWidget.saveWidgetData<String>('doc_${i}_title', doc.title);
          await HomeWidget.saveWidgetData<String>('doc_${i}_expiry', expiryStr);
          await HomeWidget.saveWidgetData<String>('doc_${i}_icon', iconType);
        } else {
          // Clear unused slots
          await HomeWidget.saveWidgetData<String>('doc_${i}_title', '');
          await HomeWidget.saveWidgetData<String>('doc_${i}_expiry', '');
          await HomeWidget.saveWidgetData<String>('doc_${i}_icon', '');
        }
      }

      // Add a boolean preference about whether the countdown is enabled globally
      // (in case the widget wants to respect the app's global setting)
      final countdownBadge = AppPreferencesService.instance.countdownBadge;
      await HomeWidget.saveWidgetData<bool>('global_countdown_badge', countdownBadge);

      // 2. Trigger the native widget updates for all 3 variants
      await HomeWidget.updateWidget(
        name: 'WidgetFullProvider',
        androidName: 'WidgetFullProvider',
      );
      await HomeWidget.updateWidget(
        name: 'WidgetExpiryProvider',
        androidName: 'WidgetExpiryProvider',
      );
      await HomeWidget.updateWidget(
        name: 'WidgetCountdownProvider',
        androidName: 'WidgetCountdownProvider',
      );
    } catch (e) {
      debugPrint('Failed to update home widget: $e');
    }
  }
}
