import 'package:flutter/material.dart';

/// Εικονίδιο εφαρμογής όπως στο launcher / build (ίδιο asset με PWA landing).
class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key, this.size = 96});

  static const String assetPath =
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.29;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Transform.scale(
          scale: 1.25,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.directions_bike_rounded,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
