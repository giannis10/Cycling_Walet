import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Αποτέλεσμα ελέγχου για ενημερώσεις στο GitHub.
class GithubUpdateResult {
  const GithubUpdateResult({
    required this.hasUpdate,
    required this.latestVersion,
    required this.releaseUrl,
  });

  final bool hasUpdate;
  final String latestVersion;
  final String releaseUrl;
}

/// Υπηρεσία ελέγχου για νέες εκδόσεις (releases) της εφαρμογής στο GitHub.
class GithubUpdateService {
  static const String _repoUrl =
      'https://api.github.com/repos/giannis10/Cycling_Walet/releases/latest';

  /// Ελέγχει αν υπάρχει νεότερη έκδοση διαθέσιμη στο GitHub.
  static Future<GithubUpdateResult?> checkForUpdates() async {
    if (kIsWeb) return null; // Στο web ενημερώνεται αυτόματα (PWA)

    try {
      final response = await http.get(Uri.parse(_repoUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String?;
        final htmlUrl = data['html_url'] as String?;

        if (tagName != null && tagName.isNotEmpty) {
          final latestVersion = tagName.replaceAll('v', '').trim();

          // Αναζήτηση απευθείας συνδέσμου για το APK (Direct Download)
          String finalUrl = htmlUrl ?? '';
          final assets = data['assets'] as List<dynamic>?;
          if (assets != null) {
            for (final asset in assets) {
              final assetUrl = asset['browser_download_url'] as String?;
              if (assetUrl != null && assetUrl.endsWith('.apk')) {
                finalUrl = assetUrl;
                break;
              }
            }
          }

          final packageInfo = await PackageInfo.fromPlatform();
          final currentVersion = packageInfo.version;

          if (finalUrl.isNotEmpty && _isNewerVersion(currentVersion, latestVersion)) {
            return GithubUpdateResult(
              hasUpdate: true,
              latestVersion: tagName,
              releaseUrl: finalUrl,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Σφάλμα ελέγχου ενημερώσεων GitHub: $e');
    }
    return null;
  }

  /// Συγκρίνει τις εκδόσεις (π.χ. 1.0.0 με 1.0.1).
  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (var i = 0; i < 3; i++) {
        final c = currentParts.length > i ? currentParts[i] : 0;
        final l = latestParts.length > i ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {
      // Σε περίπτωση λάθους parsing, υποθέτουμε ότι δεν υπάρχει update
    }
    return false;
  }
}
