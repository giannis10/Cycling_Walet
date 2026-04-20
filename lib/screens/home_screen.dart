import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/document.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';
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
  final Uri _devLink = Uri.parse('https://linktr.ee/Giannis.Tsimpouris');
  List<UserDocument> _documents = <UserDocument>[];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _notificationsEnabled = NotificationService.instance.enabled;
  int _reminderDays = NotificationService.instance.reminderDays;
  Timer? _webReminderTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _webReminderTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final docs = await _storage.loadDocuments();
    final syncedDocs = await _storage.ensureImagesInAppDirectory(docs);
    if (!mounted) return;
    setState(() {
      _documents = syncedDocs;
      _isLoading = false;
      _notificationsEnabled = NotificationService.instance.enabled;
      _reminderDays = NotificationService.instance.reminderDays;
    });
    await _syncReminders(syncedDocs);
    if (kIsWeb) {
      _startWebReminderTimer();
    }
  }

  Future<void> _save() async {
    await _storage.saveDocuments(_documents);
  }

  int _notificationIdForIndex(int index) => 1000 + index;

  Future<void> _syncReminders(List<UserDocument> docs) async {
    if (kIsWeb) {
      await _checkDueReminders(docs: docs);
      return;
    }

    for (var i = 0; i < docs.length; i++) {
      final expiry = docs[i].expiresAt;
      final notificationId = _notificationIdForIndex(i);
      if (expiry == null) {
        await NotificationService.instance.cancelNotification(notificationId);
        continue;
      }
      final reminderDate = expiry.subtract(Duration(days: _reminderDays));
      await NotificationService.instance.cancelNotification(notificationId);
      await NotificationService.instance.scheduleExpiryNotification(
        id: notificationId,
        date: reminderDate,
        title: 'Cycling Wallet',
        body: 'Το έγγραφο ${docs[i].title} λήγει σε $_reminderDays ημέρες.',
      );
    }
  }

  void _startWebReminderTimer() {
    _webReminderTimer?.cancel();
    _webReminderTimer = Timer.periodic(
        const Duration(minutes: 15), (_) => _checkDueReminders());
  }

  Future<void> _checkDueReminders({List<UserDocument>? docs}) async {
    if (!kIsWeb) {
      return;
    }

    final now = DateTime.now();
    final source = docs ?? _documents;
    var updated = false;
    final updatedDocs = List<UserDocument>.from(source);

    for (var i = 0; i < source.length; i++) {
      final doc = source[i];
      final expiry = doc.expiresAt;
      if (expiry == null) continue;

      final reminderDate = expiry.subtract(Duration(days: _reminderDays));
      final dueAt =
          DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9);
      if (now.isBefore(dueAt)) continue;

      final lastNotified = doc.lastNotifiedAt;
      final alreadyNotified =
          lastNotified != null && lastNotified.isAfter(dueAt);
      if (alreadyNotified) continue;

      final ok = await NotificationService.instance.showImmediateNotification(
        title: 'Cycling Wallet',
        body: 'Το έγγραφο ${doc.title} λήγει σε $_reminderDays ημέρες.',
      );
      if (!ok) continue;

      updatedDocs[i] = doc.copyWith(lastNotifiedAt: now);
      updated = true;
    }

    if (updated && mounted) {
      setState(() => _documents = updatedDocs);
      await _save();
    }
  }

  Future<void> _setExpiryDate(int index) async {
    if (index < 0 || index >= _documents.length) {
      return;
    }
    final doc = _documents[index];
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: doc.expiresAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;

    final updated = doc.copyWith(expiresAt: picked, lastNotifiedAt: null);
    setState(() {
      _documents = List<UserDocument>.from(_documents);
      _documents[index] = updated;
    });
    await _save();
    await _syncReminders(_documents);
  }

  Future<void> _clearExpiryDate(int index) async {
    if (index < 0 || index >= _documents.length) {
      return;
    }
    final doc = _documents[index];
    if (doc.expiresAt == null) return;

    final updated = doc.copyWith(expiresAt: null, lastNotifiedAt: null);
    setState(() {
      _documents = List<UserDocument>.from(_documents);
      _documents[index] = updated;
    });
    await _save();
    await _syncReminders(_documents);
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _toggleNotifications(bool value) async {
    final enabled = await NotificationService.instance.setEnabled(value);
    if (enabled) {
      await _syncReminders(_documents);
    }
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
    if (value && !enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Δεν δόθηκε άδεια ειδοποιήσεων.'),
        ),
      );
    }
  }

  Future<void> _setReminderDays(int days) async {
    await NotificationService.instance.setReminderDays(days);
    if (!mounted) return;
    setState(() => _reminderDays = days);
    await _syncReminders(_documents);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Οι υπενθυμίσεις θα έρχονται $_reminderDays μέρες πριν.'),
      ),
    );
  }

  Future<void> _addToCalendar(int index) async {
    if (index < 0 || index >= _documents.length) {
      return;
    }
    final doc = _documents[index];
    final expiry = doc.expiresAt;
    if (expiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ορίστε πρώτα ημερομηνία λήξης.'),
        ),
      );
      return;
    }

    final ok = await CalendarService.instance.addExpiryEvent(
      date: expiry,
      title: doc.title,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Προστέθηκε στο ημερολόγιο.'
            : 'Αποτυχία προσθήκης στο ημερολόγιο.'),
      ),
    );
  }

  Future<void> _openDevLink() async {
    final ok = await launchUrl(
      _devLink,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Δεν ήταν δυνατό το άνοιγμα του συνδέσμου.'),
        ),
      );
    }
  }

  static Future<void> openExternalUrl(
    BuildContext context,
    String url,
  ) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Δεν ήταν δυνατό το άνοιγμα του συνδέσμου.'),
        ),
      );
    }
  }

  Future<void> _pickAndSetImage(int index, {required bool second}) async {
    if (index < 0 || index >= _documents.length) {
      return;
    }
    final document = _documents[index];
    final ImageSource? source = await _showSourcePicker();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 90,
    );
    if (picked == null) return;

    final String? previousPath =
        second ? document.imagePath2 : document.imagePath1;
    String storedPath;
    try {
      storedPath = await _storage.persistImage(
        sourcePath: picked.path,
        storageKey: _storage.storageKeyForIndex(index),
        slot: second ? '2' : '1',
        previousPath: previousPath,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Αποτυχία αποθήκευσης της φωτογραφίας.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      final updated = second
          ? document.copyWith(imagePath2: storedPath)
          : document.copyWith(imagePath1: storedPath);
      _documents = List<UserDocument>.from(_documents);
      _documents[index] = updated;
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

  Widget _buildDocumentsPage() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 16 / 10,
          mainAxisSpacing: 12,
        ),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return DocumentCard(
            document: doc,
            onTap: () => _openDocument(doc),
            onEdit1: () => _pickAndSetImage(index, second: false),
            onEdit2: () => _pickAndSetImage(index, second: true),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavTap,
      backgroundColor: const Color(0xFF0C0C0C),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_rounded),
          label: 'Έγγραφα',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_active_rounded),
          label: 'Υπενθυμίσεις',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Ρυθμίσεις',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cycling Wallet'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _openDevLink,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Dev G.T'),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDocumentsPage(),
          _RemindersPage(
            documents: _documents,
            onPickDate: _setExpiryDate,
            onClearDate: _clearExpiryDate,
            onAddToCalendar: _addToCalendar,
          ),
          _SettingsPage(
            onToggleNotifications: _toggleNotifications,
            notificationsEnabled: _notificationsEnabled,
            reminderDays: _reminderDays,
            onReminderDaysChanged: _setReminderDays,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
                  late final ImageProvider provider;
                  if (kIsWeb) {
                    provider = NetworkImage(p);
                  } else {
                    provider = FileImage(File(p));
                  }
                  return PhotoView(
                    imageProvider: provider,
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
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    try {
      if (_previousBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_previousBrightness!);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _RemindersPage extends StatelessWidget {
  const _RemindersPage({
    required this.documents,
    required this.onPickDate,
    required this.onClearDate,
    required this.onAddToCalendar,
  });

  final List<UserDocument> documents;
  final ValueChanged<int> onPickDate;
  final ValueChanged<int> onClearDate;
  final ValueChanged<int> onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Υπενθυμίσεις',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._buildDocumentCards(),
      ],
    );
  }

  List<Widget> _buildDocumentCards() {
    if (documents.isEmpty) {
      return [
        Text(
          'Δεν υπάρχουν έγγραφα.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ];
    }
    return List<Widget>.generate(documents.length, (index) {
      final doc = documents[index];
      final expiryLabel = doc.expiresAt == null
          ? 'Χωρίς ημερομηνία'
          : _formatDate(doc.expiresAt!);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_note, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Λήξη: $expiryLabel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => onPickDate(index),
                        child: Text(
                          doc.expiresAt == null ? 'Ορισμός' : 'Αλλαγή',
                        ),
                      ),
                      if (doc.expiresAt != null)
                        OutlinedButton(
                          onPressed: () => onClearDate(index),
                          child: const Text('Καθαρισμός'),
                        ),
                      if (doc.expiresAt != null)
                        OutlinedButton.icon(
                          onPressed: () => onAddToCalendar(index),
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: const Text('Ημερολόγιο'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.onToggleNotifications,
    required this.notificationsEnabled,
    required this.reminderDays,
    required this.onReminderDaysChanged,
  });

  final ValueChanged<bool> onToggleNotifications;
  final bool notificationsEnabled;
  final int reminderDays;
  final ValueChanged<int> onReminderDaysChanged;
  static const String _licenseUrl =
      'https://github.com/giannis10/Cycling_Walet/blob/master/LICENSE';
  static const String _readmeUrl =
      'https://github.com/giannis10/Cycling_Walet/blob/master/README.md';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ρυθμίσεις',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.notifications_rounded,
          title: 'Ειδοποιήσεις',
          subtitle: 'Άνοιγμα ή κλείσιμο ειδοποιήσεων εφαρμογής.',
          trailing: Switch(
            value: notificationsEnabled,
            onChanged: onToggleNotifications,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.calendar_month_rounded,
          title: 'Μέρες υπενθύμισης',
          subtitle: 'Πόσες μέρες πριν τη λήξη θα έρχεται ειδοποίηση.',
          trailing: OutlinedButton(
            onPressed: () => _showReminderDaysDialog(context),
            child: Text('$reminderDays'),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.privacy_tip_rounded,
          title: 'Απόρρητο',
          subtitle: 'Άνοιγμα άδειας χρήσης.',
          onTap: () => _HomeScreenState.openExternalUrl(
            context,
            _licenseUrl,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.description_rounded,
          title: 'README',
          subtitle: 'Άνοιγμα του README στο GitHub.',
          onTap: () => _HomeScreenState.openExternalUrl(
            context,
            _readmeUrl,
          ),
        ),
      ],
    );
  }

  Future<void> _showReminderDaysDialog(BuildContext context) async {
    final controller = TextEditingController(text: reminderDays.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Μέρες υπενθύμισης'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ημέρες πριν τη λήξη',
              hintText: 'π.χ. 10',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Άκυρο'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < 1) {
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Αποθήκευση'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      onReminderDaysChanged(result);
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
