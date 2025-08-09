import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../models/document.dart';
import '../services/storage_service.dart';
import '../widgets/document_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  List<UserDocument> _documents = <UserDocument>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await _storage.loadDocuments();
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    await _storage.saveDocuments(_documents);
  }

  Future<void> _pickAndSetImage(UserDocument document,
      {required bool second}) async {
    final ImageSource? source = await _showSourcePicker();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() {
      _documents = _documents.map((d) {
        if (d.id != document.id) return d;
        return second
            ? d.copyWith(imagePath2: picked.path)
            : d.copyWith(imagePath1: picked.path);
      }).toList();
    });
    await _save();
  }

  void _openDocument(UserDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenPhoto(document: document),
      ),
    );
  }

  // Removed add-new-document flow as per request

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title:
                    const Text('Κάμερα', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Συλλογή',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 16 / 9,
                  mainAxisSpacing: 12,
                ),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  return DocumentCard(
                    document: doc,
                    onTap: () => _openDocument(doc),
                    onEdit1: () => _pickAndSetImage(doc, second: false),
                    onEdit2: () => _pickAndSetImage(doc, second: true),
                  );
                },
              ),
            ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.document});

  final UserDocument document;

  @override
  Widget build(BuildContext context) {
    final List<String> paths = [
      if (document.imagePath1 != null && document.imagePath1!.isNotEmpty)
        document.imagePath1!,
      if (document.imagePath2 != null && document.imagePath2!.isNotEmpty)
        document.imagePath2!,
    ];
    return _BrightnessScope(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(document.title),
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: paths.isEmpty
            ? const Center(
                child: Text(
                  'Δεν έχει οριστεί εικόνα',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : PageView.builder(
                itemCount: paths.length,
                itemBuilder: (context, index) {
                  final p = paths[index];
                  return PhotoView(
                    imageProvider: FileImage(File(p)),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2.5,
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black),
                  );
                },
              ),
      ),
    );
  }
}

/// Widget που ανεβάζει προσωρινά τη φωτεινότητα στο μέγιστο όσο είναι ορατό
class _BrightnessScope extends StatefulWidget {
  const _BrightnessScope({required this.child});
  final Widget child;

  @override
  State<_BrightnessScope> createState() => _BrightnessScopeState();
}

class _BrightnessScopeState extends State<_BrightnessScope> {
  double? _previousBrightness;

  @override
  void initState() {
    super.initState();
    _boostBrightness();
  }

  Future<void> _boostBrightness() async {
    try {
      _previousBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_previousBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_previousBrightness!);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
