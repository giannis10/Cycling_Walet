import 'dart:convert';
import 'dart:math';

/// Represents a user document stored as a card (e.g., UCI License),
/// supporting up to two images.
class UserDocument {
  UserDocument({
    required this.id,
    required this.title,
    this.imagePath1,
    this.imagePath2,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String? imagePath1;
  final String? imagePath2;
  final DateTime createdAt;

  UserDocument copyWith({
    String? id,
    String? title,
    String? imagePath1,
    String? imagePath2,
    DateTime? createdAt,
  }) {
    return UserDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath1: imagePath1 ?? this.imagePath1,
      imagePath2: imagePath2 ?? this.imagePath2,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String? firstAvailableImagePath() {
    return imagePath1?.isNotEmpty == true
        ? imagePath1
        : (imagePath2?.isNotEmpty == true ? imagePath2 : null);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'imagePath1': imagePath1,
      'imagePath2': imagePath2,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserDocument.fromMap(Map<String, dynamic> map) {
    // Backward compatibility: if only 'imagePath' exists, map it to imagePath1
    final String? legacy = map['imagePath'] as String?;
    return UserDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      imagePath1: (map['imagePath1'] as String?) ?? legacy,
      imagePath2: map['imagePath2'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserDocument.fromJson(String source) =>
      UserDocument.fromMap(json.decode(source) as Map<String, dynamic>);
}

final Random _idRandom = Random();
const int _idRandMax = 1000000000;

String generateDocumentId() {
  return '${DateTime.now().microsecondsSinceEpoch}_${_idRandom.nextInt(_idRandMax)}';
}
