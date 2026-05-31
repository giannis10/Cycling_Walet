import '../models/document_card_kind.dart';

/// Αποτέλεσμα ανάγνωσης ημερομηνίας από κείμενο κάρτας.
class ExtractedDocumentDate {
  const ExtractedDocumentDate({
    required this.expiryDate,
    this.issueDate,
    required this.description,
  });

  final DateTime expiryDate;
  final DateTime? issueDate;
  final String description;
}

/// Εξαγωγή ημερομηνίας από OCR κείμενο ανά τύπο κάρτας.
class DocumentDateParser {
  static const String _datePattern =
      r'(\d{1,2})\s*[./\-]\s*(\d{1,2})\s*[./\-]\s*(\d{2,4})';

  static final RegExp _dateCapture = RegExp(_datePattern);

  static ExtractedDocumentDate? parse(
    String ocrText, {
    required DocumentCardKind kind,
  }) {
    final normalized = _normalizeGreek(ocrText);

    switch (kind) {
      case DocumentCardKind.uci:
        return _parseExpiry(
          normalized,
          labels: const [
            r'valid\s+until',
            r'valid\s+thru',
            r'valid\s+till',
            r'expires',
            r'expiry',
            r'ληγει',
          ],
          description: 'λήξη UCI',
        );
      case DocumentCardKind.eop:
        return _parseExpiry(
          normalized,
          labels: const [
            r'ισχυει\s+εως',
            r'ισχει\s+εως',
            r'valid\s+until',
          ],
          description: 'λήξη ΕΟΠ',
        );
      case DocumentCardKind.health:
        return _parseHealthIssueDate(normalized);
      case DocumentCardKind.other:
        return _parseExpiry(
          normalized,
          labels: const [
            r'valid\s+until',
            r'ισχυει\s+εως',
            r'ληγει',
            r'expires',
          ],
          description: 'λήξη',
        );
    }
  }

  static ExtractedDocumentDate? _parseExpiry(
    String text, {
    required List<String> labels,
    required String description,
  }) {
    for (final label in labels) {
      final pattern = RegExp(
        '$label\\s*[:.]?\\s*$_datePattern',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final date = _dateFromMatch(match);
      if (date != null) {
        return ExtractedDocumentDate(
          expiryDate: date,
          description: description,
        );
      }
    }

    final afterUntil = RegExp(
      r'(?:until|εως|expires?)\s*[:\s]*([^\n]{0,40})',
      caseSensitive: false,
    ).firstMatch(text);
    if (afterUntil != null) {
      final date = _firstDateIn(afterUntil.group(1) ?? '');
      if (date != null) {
        return ExtractedDocumentDate(
          expiryDate: date,
          description: description,
        );
      }
    }

    return null;
  }

  static ExtractedDocumentDate? _parseHealthIssueDate(String text) {
    final issuePatterns = <RegExp>[
      RegExp(
        r'ημερομηνια\s*(?:εκδοσης)?\s*[:\s]*' + _datePattern,
        caseSensitive: false,
      ),
      RegExp(
        r'ημ\.?\s*[:\s]*' + _datePattern,
        caseSensitive: false,
      ),
    ];

    for (final pattern in issuePatterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final issue = _dateFromMatch(match);
      if (issue == null) continue;
      final expiry = _addOneYear(issue);
      return ExtractedDocumentDate(
        expiryDate: expiry,
        issueDate: issue,
        description: 'έκδοση κάρτας υγείας',
      );
    }

    return null;
  }

  static DateTime? _firstDateIn(String fragment) {
    final match = _dateCapture.firstMatch(fragment);
    if (match == null) return null;
    return _dateFromMatch(match);
  }

  static DateTime? _dateFromMatch(RegExpMatch match) {
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    if (year < 100) {
      year += 2000;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static DateTime _addOneYear(DateTime issue) {
    try {
      return DateTime(issue.year + 1, issue.month, issue.day);
    } catch (_) {
      return DateTime(issue.year + 1, issue.month, 28);
    }
  }

  static String _normalizeGreek(String input) {
    return input
        .toLowerCase()
        .replaceAll('ά', 'α')
        .replaceAll('έ', 'ε')
        .replaceAll('ή', 'η')
        .replaceAll('ί', 'ι')
        .replaceAll('ό', 'ο')
        .replaceAll('ύ', 'υ')
        .replaceAll('ώ', 'ω')
        .replaceAll('ϊ', 'ι')
        .replaceAll('ΐ', 'ι')
        .replaceAll('ς', 'σ');
  }
}
