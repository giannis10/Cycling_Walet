import 'package:flutter_test/flutter_test.dart';

import 'package:cycling_races/models/document.dart';

void main() {
  test('UserDocument maps legacy imagePath', () {
    final doc = UserDocument.fromMap({
      'id': '1',
      'title': 'UCI',
      'imagePath': '/tmp/sample.jpg',
    });
    expect(doc.imagePath1, '/tmp/sample.jpg');
    expect(doc.imagePath2, isNull);
  });
}
