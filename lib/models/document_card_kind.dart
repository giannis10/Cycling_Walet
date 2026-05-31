/// Τύπος κάρτας για διαφορετική ανάγνωση ημερομηνίας από OCR.
enum DocumentCardKind {
  uci,
  eop,
  health,
  other,
}

DocumentCardKind documentCardKindFromTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('uci')) {
    return DocumentCardKind.uci;
  }
  if (lower.contains('εοπ') || lower.contains('eop')) {
    return DocumentCardKind.eop;
  }
  if (lower.contains('υγε') ||
      lower.contains('health') ||
      lower.contains('karta') ||
      lower.contains('κάρτα')) {
    return DocumentCardKind.health;
  }
  return DocumentCardKind.other;
}
