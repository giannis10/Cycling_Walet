import 'package:cycling_races/utils/expiry_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('countdown label shows days remaining', () {
    final expiry = DateTime.now().add(const Duration(days: 23));
    final text = ExpiryDisplay.label(expiry, countdownBadge: true);
    expect(text, 'Λήγει σε 23 μέρες');
  });

  test('urgent color when under 30 days', () {
    final expiry = DateTime.now().add(const Duration(days: 10));
    final color = ExpiryDisplay.labelColor(
      expiry,
      countdownBadge: true,
    );
    expect(color, const Color(0xFFFCA5A5));
  });

  test('classic label shows formatted date', () {
    final expiry = DateTime(2025, 3, 15);
    final text = ExpiryDisplay.label(expiry, countdownBadge: false);
    expect(text, 'Λήγει 15/03/2025');
  });
}
