import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
      final docs = list
          .map((e) => UserDocument.fromMap(e as Map<String, dynamic>))
          .toList();
      return await _ensureUniqueDocumentIds(docs);
    } catch (_) {
      return _defaultDocuments();
    }
  }

  Future<void> saveDocuments(List<UserDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(documents.map((e) => e.toMap()).toList());
    await prefs.setString(StorageKeys.documents, raw);
  }

  Future<String> persistImage({
    required String sourcePath,
    required String storageKey,
    required String slot,
    String? previousPath,
  }) async {
    if (kIsWeb) {
      return sourcePath;
    }
    final imagesDir = await _ensureImagesDirectory();
    final extension = p.extension(sourcePath);
    final safeExtension = extension.isNotEmpty ? extension : '.jpg';
    final fileName = '${storageKey}_$slot$safeExtension';
    final destPath = p.join(imagesDir.path, fileName);

    if (!p.equals(sourcePath, destPath)) {
      await File(sourcePath).copy(destPath);
    }
    await _deleteIfAppImage(previousPath, imagesDir.path);
    return destPath;
  }

  Future<List<UserDocument>> ensureImagesInAppDirectory(
      List<UserDocument> documents) async {
    if (kIsWeb) {
      return documents;
    }
    final imagesDir = await _ensureImagesDirectory();
    bool changed = false;

    final updated = <UserDocument>[];
    for (var i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final storageKey = storageKeyForIndex(i);
      final newPath1 = await _copyToAppDirIfNeeded(
        doc.imagePath1,
        imagesDir.path,
        storageKey,
        '1',
      );
      final newPath2 = await _copyToAppDirIfNeeded(
        doc.imagePath2,
        imagesDir.path,
        storageKey,
        '2',
      );
      if (newPath1 != doc.imagePath1 || newPath2 != doc.imagePath2) {
        changed = true;
      }
      updated.add(doc.copyWith(imagePath1: newPath1, imagePath2: newPath2));
    }

    if (changed) {
      await saveDocuments(updated);
    }
    return updated;
  }

  Future<String?> loadLastViewedId() async {
    // Deprecated: no longer auto-opening last viewed document
    return null;
  }

  Future<void> saveLastViewedId(String? id) async {
    // Deprecated: noop
  }

  String storageKeyForIndex(int index) => 'doc_$index';

  Future<List<UserDocument>> _ensureUniqueDocumentIds(
      List<UserDocument> documents) async {
    final seen = <String>{};
    bool changed = false;
    final updated = <UserDocument>[];

    for (final doc in documents) {
      var id = doc.id;
      if (seen.contains(id)) {
        id = generateDocumentId();
        changed = true;
      }
      seen.add(id);
      updated.add(doc.copyWith(id: id));
    }

    if (changed) {
      await saveDocuments(updated);
    }
    return updated;
  }

  Future<Directory> _ensureImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  Future<String?> _copyToAppDirIfNeeded(
    String? sourcePath,
    String imagesDirPath,
    String storageKey,
    String slot,
  ) async {
    if (sourcePath == null || sourcePath.isEmpty) {
      return sourcePath;
    }
    if (p.isWithin(imagesDirPath, sourcePath)) {
      return sourcePath;
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return sourcePath;
    }

    final extension = p.extension(sourcePath);
    final safeExtension = extension.isNotEmpty ? extension : '.jpg';
    final destPath = p.join(imagesDirPath, '${storageKey}_$slot$safeExtension');
    if (!p.equals(sourcePath, destPath)) {
      await sourceFile.copy(destPath);
    }
    return destPath;
  }

  Future<void> _deleteIfAppImage(
    String? path,
    String imagesDirPath,
  ) async {
    if (path == null || path.isEmpty) {
      return;
    }
    if (!p.isWithin(imagesDirPath, path)) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  List<UserDocument> _defaultDocuments() {
    return <UserDocument>[
      UserDocument(id: generateDocumentId(), title: 'UCI'),
      UserDocument(id: generateDocumentId(), title: 'ΕΟΠ'),
      UserDocument(id: generateDocumentId(), title: 'Κάρτα Υγείας'),
    ];
  }
}
