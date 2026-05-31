import 'package:cycling_races/models/document_card_kind.dart';
import 'package:cycling_races/services/document_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UCI parses Valid until date', () {
    final result = DocumentDateParser.parse(
      'License Valid until: 15/03/2026',
      kind: DocumentCardKind.uci,
    );
    expect(result, isNotNull);
    expect(result!.expiryDate.year, 2026);
    expect(result.expiryDate.month, 3);
    expect(result.expiryDate.day, 15);
  });

  test('EOP parses Ισχύει έως date', () {
    final result = DocumentDateParser.parse(
      'Ισχύει έως: 01.12.2025',
      kind: DocumentCardKind.eop,
    );
    expect(result, isNotNull);
    expect(result!.expiryDate.day, 1);
    expect(result.expiryDate.month, 12);
  });

  test('Health card adds one year from issue date', () {
    final result = DocumentDateParser.parse(
      'Ημερομηνία: 10/05/2024',
      kind: DocumentCardKind.health,
    );
    expect(result, isNotNull);
    expect(result!.issueDate!.year, 2024);
    expect(result.expiryDate.year, 2025);
    expect(result.expiryDate.month, 5);
    expect(result.expiryDate.day, 10);
  });
}
