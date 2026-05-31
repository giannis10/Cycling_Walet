import 'package:flutter/material.dart';

/// Κείμενο και χρώμα εμφάνισης ημερομηνίας λήξης / αντίστροφης μέτρησης.
class ExpiryDisplay {
  ExpiryDisplay._();

  static const int urgentThresholdDays = 30;

  static int daysUntil(DateTime expiry) {
    final now = DateTime.now();
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final today = DateTime(now.year, now.month, now.day);
    return expiryDay.difference(today).inDays;
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String label(
    DateTime? expiresAt, {
    required bool countdownBadge,
  }) {
    if (expiresAt == null) {
      return 'Χωρίς ημερομηνία λήξης';
    }
    if (!countdownBadge) {
      return 'Λήγει ${formatDate(expiresAt)}';
    }

    final days = daysUntil(expiresAt);
    if (days < 0) {
      final past = -days;
      return past == 1
          ? 'Έληξε πριν 1 μέρα'
          : 'Έληξε πριν $past μέρες';
    }
    if (days == 0) {
      return 'Λήγει σήμερα';
    }
    return days == 1 ? 'Λήγει σε 1 μέρα' : 'Λήγει σε $days μέρες';
  }

  static String remindersExpiryLine(
    DateTime? expiresAt, {
    required bool countdownBadge,
  }) {
    if (expiresAt == null) {
      return 'Χωρίς ημερομηνία';
    }
    if (!countdownBadge) {
      return 'Λήξη: ${formatDate(expiresAt)}';
    }
    return 'Λήξη: ${label(expiresAt, countdownBadge: true)}';
  }

  static Color labelColor(
    DateTime? expiresAt, {
    required bool countdownBadge,
    Color? defaultColor,
  }) {
    final fallback = defaultColor ?? Colors.white.withValues(alpha: 0.7);
    if (expiresAt == null || !countdownBadge) {
      return fallback;
    }
    final days = daysUntil(expiresAt);
    if (days < urgentThresholdDays) {
      return const Color(0xFFFCA5A5);
    }
    return const Color(0xFF86EFAC);
  }

  static bool showUrgentBadge(DateTime? expiresAt, bool countdownBadge) {
    if (expiresAt == null || !countdownBadge) {
      return false;
    }
    return daysUntil(expiresAt) < urgentThresholdDays;
  }

  static String? badgeShortText(DateTime? expiresAt, bool countdownBadge) {
    if (!showUrgentBadge(expiresAt, countdownBadge)) {
      return null;
    }
    final days = daysUntil(expiresAt!);
    if (days < 0) {
      return '!';
    }
    return '$days';
  }
}
