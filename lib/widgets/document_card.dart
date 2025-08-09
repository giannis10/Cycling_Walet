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
    String iconAsset = _iconAssetFor(document.title);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Solid background
            Positioned.fill(
              child: Container(
                color: const Color.fromRGBO(189, 202, 208, 1),
              ),
            ),
            // Center icon asset (falls back to Material icon if missing)
            Positioned.fill(
              child: Center(
                child: Image.asset(
                  iconAsset,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.credit_card,
                    size: 120,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            // Overlay gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Title + Edit buttons
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Επεξεργασία Φωτογραφίας 1',
                    child: IconButton(
                      onPressed: onEdit1,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                      ),
                      icon: const Icon(Icons.filter_1, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Επεξεργασία Φωτογραφίας 2',
                    child: IconButton(
                      onPressed: onEdit2,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                      ),
                      icon: const Icon(Icons.filter_2, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _iconAssetFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('uci')) return 'assets/icons/uci.png';
    if (lower.contains('εοπ') || lower.contains('eop'))
      return 'assets/icons/eop.png';
    if (lower.contains('υγε') ||
        lower.contains('health') ||
        lower.contains('karta')) {
      return 'assets/icons/karta_igias.png';
    }
    return 'assets/icons/uci.png';
  }
}
