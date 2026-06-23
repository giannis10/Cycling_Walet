import 'package:flutter/foundation.dart';

import '../models/document_card_kind.dart';
import 'document_date_parser.dart';
import 'text_recognition_stub.dart'
    if (dart.library.io) 'text_recognition_io.dart' as ocr;

/// Ανάγνωση ημερομηνίας από φωτογραφία κάρτας (OCR). Διαθέσιμο σε Android/iOS.
class DateExtractionService {
  DateExtractionService._();

  static final DateExtractionService instance = DateExtractionService._();

  bool get isSupported => !kIsWeb;

  Future<ExtractedDocumentDate?> extractFromImage({
    required String imagePath,
    required String documentTitle,
  }) async {
    if (kIsWeb || imagePath.isEmpty) {
      return null;
    }

    try {
      final text = await ocr.recognizeTextFromImagePath(imagePath);
      if (text.trim().isEmpty) {
        return null;
      }
      final kind = documentCardKindFromTitle(documentTitle);
      return DocumentDateParser.parse(text, kind: kind);
    } catch (e) {
      debugPrint('Date OCR failed: $e');
      return null;
    }
  }

  Future<String> getRawOcrText(String imagePath) async {
    if (kIsWeb || imagePath.isEmpty) return '';
    try {
      return await ocr.recognizeTextFromImagePath(imagePath);
    } catch (_) {
      return 'Error extracting text';
    }
  }
}
