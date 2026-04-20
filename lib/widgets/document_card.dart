import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/document.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onEdit1,
    required this.onEdit2,
  });

  final UserDocument document;
  final VoidCallback onTap;
  final VoidCallback onEdit1;
  final VoidCallback onEdit2;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(document.title);
    final imageCount = _imageCount();
    final status = _statusFor(imageCount);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: style.gradient,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: style.borderColor),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(iconAsset: style.iconAsset),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Φωτογραφίες: $imageCount/2',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _expiryLabel(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ImageSlot(
                        label: 'Μπρος',
                        imagePath: document.imagePath1,
                        onTap: onEdit1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImageSlot(
                        label: 'Πίσω',
                        imagePath: document.imagePath2,
                        onTap: onEdit2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _imageCount() {
    var count = 0;
    if (document.imagePath1?.isNotEmpty == true) count++;
    if (document.imagePath2?.isNotEmpty == true) count++;
    return count;
  }

  String _expiryLabel() {
    final expiresAt = document.expiresAt;
    if (expiresAt == null) {
      return 'Χωρίς ημερομηνία λήξης';
    }
    return 'Λήγει ${_formatDate(expiresAt)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  _CardStyle _styleFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('uci')) {
      return const _CardStyle(
        iconAsset: 'assets/icons/uci.png',
        gradient: [Color(0xFF1B2E5D), Color(0xFF0F1A36)],
        borderColor: Color(0x334F6FD8),
      );
    }
    if (lower.contains('εοπ') || lower.contains('eop')) {
      return const _CardStyle(
        iconAsset: 'assets/icons/eop.png',
        gradient: [Color(0xFF1E3A2F), Color(0xFF101F18)],
        borderColor: Color(0x334ED18C),
      );
    }
    if (lower.contains('υγε') ||
        lower.contains('health') ||
        lower.contains('karta')) {
      return const _CardStyle(
        iconAsset: 'assets/icons/karta_igias.png',
        gradient: [Color(0xFF3B1B1B), Color(0xFF221010)],
        borderColor: Color(0x33D96A6A),
      );
    }
    return const _CardStyle(
      iconAsset: 'assets/icons/uci.png',
      gradient: [Color(0xFF2A2E3D), Color(0xFF191B26)],
      borderColor: Color(0x33464664),
    );
  }

  _StatusInfo _statusFor(int count) {
    if (count >= 2) {
      return _StatusInfo(
        label: 'Έτοιμο',
        background: const Color(0x334ADE80),
        foreground: const Color(0xFF86EFAC),
      );
    }
    if (count == 1) {
      return _StatusInfo(
        label: 'Μερικό',
        background: const Color(0x33FBBF24),
        foreground: const Color(0xFFFCD34D),
      );
    }
    return _StatusInfo(
      label: 'Χωρίς φωτο',
      background: Colors.white.withValues(alpha: 0.18),
      foreground: Colors.white70,
    );
  }
}

class _CardStyle {
  const _CardStyle({
    required this.iconAsset,
    required this.gradient,
    required this.borderColor,
  });

  final String iconAsset;
  final List<Color> gradient;
  final Color borderColor;
}

class _StatusInfo {
  _StatusInfo({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _StatusInfo status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.foreground.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.iconAsset});

  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        iconAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const Icon(
          Icons.credit_card,
          color: Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  final String label;
  final String? imagePath;
  final VoidCallback onTap;

  bool get _hasImage => imagePath?.isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Stack(
            children: [
              if (_hasImage) Positioned.fill(child: _PreviewImage(path: imagePath!)),
              if (!_hasImage)
                Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.white.withValues(alpha: 0.65),
                    size: 28,
                  ),
                ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final image = kIsWeb
        ? Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: image,
    );
  }
}
