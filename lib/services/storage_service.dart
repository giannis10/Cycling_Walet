import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/document.dart';

class StorageKeys {
  static const String documents = 'documents_v1';
}

/// Simple local storage using SharedPreferences.
class StorageService {
  Future<List<UserDocument>> loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.documents);
    if (raw == null || raw.isEmpty) {
      return _defaultDocuments();
    }
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => UserDocument.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaultDocuments();
    }
  }

  Future<void> saveDocuments(List<UserDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(documents.map((e) => e.toMap()).toList());
    await prefs.setString(StorageKeys.documents, raw);
  }

  Future<String?> loadLastViewedId() async {
    // Deprecated: no longer auto-opening last viewed document
    return null;
  }

  Future<void> saveLastViewedId(String? id) async {
    // Deprecated: noop
  }

  List<UserDocument> _defaultDocuments() {
    return <UserDocument>[
      UserDocument(id: generateDocumentId(), title: 'UCI'),
      UserDocument(id: generateDocumentId(), title: 'ΕΟΠ'),
      UserDocument(id: generateDocumentId(), title: 'Κάρτα Υγείας'),
    ];
  }
}
