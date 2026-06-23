import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/document.dart';
import '../services/app_preferences_service.dart';
import '../services/calendar_service.dart';
import '../services/date_extraction_service.dart';
import '../services/document_date_parser.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../tour/app_feature_tour.dart';
import '../utils/expiry_display.dart';
import '../widgets/document_card.dart';
import '../services/github_update_service.dart';

/// Κεντρική οθόνη της εφαρμογής που διαχειρίζεται το UI (Bottom Navigation)
/// και την εναλλαγή των επιμέρους καρτελών (Έγγραφα, Υπενθυμίσεις, Ρυθμίσεις).
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
  bool _countdownBadge = AppPreferencesService.instance.countdownBadge;
  Timer? _webReminderTimer;
  final AppFeatureTourKeys _tourKeys = AppFeatureTourKeys();
  final ScrollController _remindersScrollController = ScrollController();
  bool _tourScheduled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _webReminderTimer?.cancel();
    _remindersScrollController.dispose();
    super.dispose();
  }

  /// Αρχική φόρτωση δεδομένων από την τοπική μνήμη.
  Future<void> _load() async {
    final docs = await _storage.loadDocuments();
    final syncedDocs = await _storage.ensureImagesInAppDirectory(docs);
    
    // Ελάχιστη καθυστέρηση για αποφυγή τρεμοπαίγματος (flickering) της splash οθόνης.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    
    if (!mounted) return;
    setState(() {
      _documents = syncedDocs;
      _isLoading = false;
      _notificationsEnabled = NotificationService.instance.enabled;
      _reminderDays = NotificationService.instance.reminderDays;
      _countdownBadge = AppPreferencesService.instance.countdownBadge;
    });
    await _syncReminders(syncedDocs);
    if (kIsWeb) {
      _startWebReminderTimer();
    }
    _scheduleFeatureTourIfNeeded();

    // Check for updates after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkForUpdates();
    });
  }

  /// Ελέγχει στο παρασκήνιο για νέα έκδοση (Release) στο GitHub.
  Future<void> _checkForUpdates() async {
    final update = await GithubUpdateService.checkForUpdates();
    if (update != null && update.hasUpdate && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Νέα Έκδοση'),
          content: Text(
            'Υπάρχει διαθέσιμη μια νέα έκδοση της εφαρμογής (${update.latestVersion}). Θέλετε να την κατεβάσετε τώρα;',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Αργότερα'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final url = Uri.parse(update.releaseUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Λήψη'),
            ),
          ],
        ),
      );
    }
  }

  void _scheduleFeatureTourIfNeeded() {
    if (_tourScheduled || AppPreferencesService.instance.featureTourCompleted) {
      return;
    }
    _tourScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showFeatureTour(force: false);
    });
  }

  Future<void> _navigateForTour(int tabIndex) async {
    if (_selectedIndex != tabIndex) {
      setState(() => _selectedIndex = tabIndex);
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _prepareTourStep(String identify) async {
    final tabIndex = AppFeatureTourKeys.tabIndexFor(identify);
    await _navigateForTour(tabIndex);

    if (tabIndex == 1 && _remindersScrollController.hasClients) {
      await _remindersScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      await WidgetsBinding.instance.endOfFrame;
    }

    final key = _tourKeys.keyFor(identify);
    if (key != null) {
      await _waitForTourTarget(key);
    }
  }

  Future<void> _waitForTourTarget(GlobalKey key) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted) return;

      final targetContext = key.currentContext;
      if (targetContext != null && targetContext.mounted) {
        final renderBox = targetContext.findRenderObject();
        if (renderBox is RenderBox &&
            renderBox.hasSize &&
            renderBox.size.longestSide > 1) {
          await Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: 0.25,
          );
          await WidgetsBinding.instance.endOfFrame;
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return;
        }
      }

      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Εμφάνιση του διαδραστικού οδηγού λειτουργιών (Feature Tour).
  Future<void> showFeatureTour({bool force = false}) async {
    if (!mounted || _isLoading) return;
    if (!force && AppPreferencesService.instance.featureTourCompleted) {
      return;
    }
    await _prepareTourStep('nav_documents');
    if (!mounted) return;

    await AppFeatureTour.show(
      context: context,
      keys: _tourKeys,
      onPrepareStep: _prepareTourStep,
      onFinished: () =>
          AppPreferencesService.instance.setFeatureTourCompleted(true),
      onSkipped: () =>
          AppPreferencesService.instance.setFeatureTourCompleted(true),
    );
  }

  Future<void> _save() async {
    await _storage.saveDocuments(_documents);
  }

  int _notificationIdForDocument(UserDocument doc) =>
      1000 + doc.id.hashCode.abs() % 900000;

  bool _shouldScheduleReminder(UserDocument doc) {
    return NotificationService.instance.enabled &&
        doc.remindersEnabled &&
        doc.expiresAt != null;
  }

  Future<void> _syncReminders(List<UserDocument> docs) async {
    if (kIsWeb) {
      await _checkDueReminders(docs: docs);
      return;
    }

    for (final doc in docs) {
      final notificationId = _notificationIdForDocument(doc);
      if (!_shouldScheduleReminder(doc)) {
        await NotificationService.instance.cancelNotification(notificationId);
        continue;
      }
      final expiry = doc.expiresAt!;
      var reminderDate = expiry.subtract(Duration(days: _reminderDays));
      final now = DateTime.now();
      if (reminderDate.isBefore(now) && expiry.isAfter(now)) {
        var fallback = DateTime(now.year, now.month, now.day, 9);
        if (fallback.isBefore(now)) {
          fallback = fallback.add(const Duration(days: 1));
        }
        if (fallback.isBefore(expiry) ||
            _isSameDay(fallback, expiry)) {
          reminderDate = fallback;
        }
      }
      await NotificationService.instance.cancelNotification(notificationId);
      await NotificationService.instance.scheduleExpiryNotification(
        id: notificationId,
        date: reminderDate,
        expiry: expiry,
        title: 'Cycling Wallet',
        body: 'Το έγγραφο ${doc.title} λήγει σε $_reminderDays ημέρες.',
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
      if (!doc.remindersEnabled || !NotificationService.instance.enabled) {
        continue;
      }
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

    final updated =
        doc.copyWith(expiresAt: picked, clearLastNotifiedAt: true);
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

    final updated = doc.copyWith(
      clearExpiresAt: true,
      clearLastNotifiedAt: true,
    );
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
    setState(() => _notificationsEnabled = value);
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

  Future<void> _toggleDocumentReminders(int index, bool value) async {
    if (index < 0 || index >= _documents.length) return;
    setState(() {
      _documents = List<UserDocument>.from(_documents);
      _documents[index] =
          _documents[index].copyWith(remindersEnabled: value);
    });
    await _save();
    await _syncReminders(_documents);
    if (!mounted) return;
    final title = _documents[index].title;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Ειδοποιήσεις ενεργές για $title.'
              : 'Δεν θα σταλούν ειδοποιήσεις για $title.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _toggleCountdownBadge(bool value) async {
    setState(() => _countdownBadge = value);
    await AppPreferencesService.instance.setCountdownBadge(value);
  }

  Future<void> _setReminderDays(int days) async {
    await NotificationService.instance.setReminderDays(days);
    if (!mounted) return;
    setState(() => _reminderDays = days);
    await _syncReminders(_documents);
    if (!mounted) return;
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
    await _tryExtractDateAfterImagePick(index);
  }

  Future<void> _tryExtractDateAfterImagePick(int index) async {
    if (!DateExtractionService.instance.isSupported) {
      return;
    }
    if (index < 0 || index >= _documents.length || !mounted) return;

    final doc = _documents[index];
    final paths = <String>[
      if (doc.imagePath1?.isNotEmpty == true) doc.imagePath1!,
      if (doc.imagePath2?.isNotEmpty == true) doc.imagePath2!,
    ];
    if (paths.isEmpty) return;

    ExtractedDocumentDate? extracted;
    for (final path in paths) {
      extracted = await DateExtractionService.instance.extractFromImage(
        imagePath: path,
        documentTitle: doc.title,
      );
      if (extracted != null) break;
    }

    if (!mounted || extracted == null) return;
    await _applyExtractedDate(index, extracted);
  }

  Future<void> _applyExtractedDate(
    int index,
    ExtractedDocumentDate extracted,
  ) async {
    if (index < 0 || index >= _documents.length || !mounted) return;

    final doc = _documents[index];
    final newExpiry = extracted.expiryDate;
    final sameExpiry =
        doc.expiresAt != null && _isSameDay(doc.expiresAt!, newExpiry);

    if (sameExpiry) {
      if (extracted.issueDate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Η ημερομηνία λήξης είναι ήδη σωστή '
              '(${_formatDateForMessage(newExpiry)}).',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (doc.expiresAt != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final issue = extracted.issueDate;
          final body = issue != null
              ? 'Έκδοση: ${_formatDateForMessage(issue)}\n'
                  'Νέα λήξη: ${_formatDateForMessage(newExpiry)}'
              : 'Νέα λήξη: ${_formatDateForMessage(newExpiry)}';
          return AlertDialog(
            title: const Text('Βρέθηκε ημερομηνία'),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Όχι'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Ενημέρωση'),
              ),
            ],
          );
        },
      );
      if (replace != true || !mounted) return;
    }

    setState(() {
      _documents = List<UserDocument>.from(_documents);
      _documents[index] = doc.copyWith(
        expiresAt: newExpiry,
        clearLastNotifiedAt: true,
      );
    });
    await _save();
    await _syncReminders(_documents);

    if (!mounted) return;
    final message = extracted.issueDate != null
        ? 'Κάρτα υγείας: έκδοση ${_formatDateForMessage(extracted.issueDate!)} '
            '→ λήξη ${_formatDateForMessage(newExpiry)}'
        : 'Ορίστηκε λήξη: ${_formatDateForMessage(newExpiry)}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDateForMessage(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
      return Center(
        child: SizedBox(
          width: 240,
          height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SpinKitRipple(
                  color: Colors.white24,
                  size: 240.0,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/icons/playstore-icon.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SpinKitDualRing(
                  color: Colors.white70,
                  size: 140.0,
                  lineWidth: 3.0,
                ),
              ],
            ),
          ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return DocumentCard(
          document: doc,
          countdownBadge: _countdownBadge,
          headerKey: index == 0 ? _tourKeys.cardView : null,
          photosKey: index == 0 ? _tourKeys.cardPhotos : null,
          onTap: () => _openDocument(doc),
          onEdit1: () => _pickAndSetImage(index, second: false),
          onEdit2: () => _pickAndSetImage(index, second: true),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    const items = <_NavItem>[
      _NavItem(
        label: 'Έγγραφα',
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
      ),
      _NavItem(
        label: 'Υπενθυμίσεις',
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications_active_rounded,
      ),
      _NavItem(
        label: 'Ρυθμίσεις',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ];

    return Material(
      color: const Color(0xFF0C0C0C),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = _selectedIndex == index;
              final color = selected ? Colors.white : Colors.white70;
              final navKey = index == 0
                  ? _tourKeys.navDocuments
                  : (index == 1
                      ? _tourKeys.navReminders
                      : _tourKeys.navSettings);
              return Expanded(
                key: navKey,
                child: InkWell(
                  onTap: () => _onNavTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SpinKitFadingCube(
            color: Colors.white,
            size: 50.0,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cycling Wallet'),
        backgroundColor: Colors.transparent,
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
            notificationsEnabled: _notificationsEnabled,
            countdownBadge: _countdownBadge,
            ocrSupported: DateExtractionService.instance.isSupported,
            scrollController: _remindersScrollController,
            onPickDate: _setExpiryDate,
            onClearDate: _clearExpiryDate,
            onAddToCalendar: _addToCalendar,
            onToggleDocumentReminders: _toggleDocumentReminders,
            onScanDate: _tryExtractDateAfterImagePick,
            tourDateButtonKey: _tourKeys.reminderDateButton,
            tourSwitchKey: _tourKeys.reminderSwitch,
          ),
          _SettingsPage(
            onToggleNotifications: _toggleNotifications,
            notificationsEnabled: _notificationsEnabled,
            reminderDays: _reminderDays,
            onReminderDaysChanged: _setReminderDays,
            countdownBadge: _countdownBadge,
            onToggleCountdownBadge: _toggleCountdownBadge,
            onShowFeatureTour: () => showFeatureTour(force: true),
            notificationsTourKey: _tourKeys.settingsNotifications,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(document.title),
          centerTitle: true,
          backgroundColor: Colors.transparent,
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
                        const BoxDecoration(color: Colors.transparent),
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
    required this.notificationsEnabled,
    required this.countdownBadge,
    required this.ocrSupported,
    required this.onPickDate,
    required this.onClearDate,
    required this.onAddToCalendar,
    required this.onToggleDocumentReminders,
    required this.onScanDate,
    required this.scrollController,
    this.tourDateButtonKey,
    this.tourSwitchKey,
  });

  final List<UserDocument> documents;
  final bool notificationsEnabled;
  final bool countdownBadge;
  final bool ocrSupported;
  final ValueChanged<int> onPickDate;
  final ValueChanged<int> onClearDate;
  final ValueChanged<int> onAddToCalendar;
  final void Function(int index, bool value) onToggleDocumentReminders;
  final ValueChanged<int> onScanDate;
  final ScrollController scrollController;
  final Key? tourDateButtonKey;
  final Key? tourSwitchKey;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
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
        if (!notificationsEnabled) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: Text(
              'Οι γενικές ειδοποιήσεις είναι κλειστές (Ρυθμίσεις). '
              'Μπορείς ακόμα να απενεργοποιήσεις ανά κάρτα — θα ισχύσει '
              'όταν ξαναανοίξεις τις ειδοποιήσεις.',
              style: TextStyle(
                color: Colors.amber.shade100,
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (ocrSupported)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Με φωτογραφία κάρτας η ημερομηνία εντοπίζεται αυτόματα '
              '(UCI: Valid until, ΕΟΠ: Ισχύει έως, Υγεία: Ημερομηνία +1 έτος).',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Στο browser/PWA η αυτόματη ανάγνωση ημερομηνίας δεν είναι '
              'διαθέσιμη — χρησιμοποίησε «Ορισμός» ή την εγκατεστημένη εφαρμογή.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
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
      final expiryLabel = ExpiryDisplay.remindersExpiryLine(
        doc.expiresAt,
        countdownBadge: countdownBadge,
      );
      final expiryColor = ExpiryDisplay.labelColor(
        doc.expiresAt,
        countdownBadge: countdownBadge,
        defaultColor: Colors.white.withValues(alpha: 0.7),
      );
      final hasImage = doc.imagePath1?.isNotEmpty == true ||
          doc.imagePath2?.isNotEmpty == true;
      final remindersOn =
          notificationsEnabled && doc.remindersEnabled;
      final reminderStatus = !notificationsEnabled
          ? 'Ειδοποιήσεις εφαρμογής κλειστές'
          : (doc.remindersEnabled
              ? 'Ειδοποιήσεις: ενεργές'
              : 'Ειδοποιήσεις: απενεργοποιημένες');

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
            const Icon(Icons.event_note, color: Colors.white70),
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
                    expiryLabel,
                    style: TextStyle(
                      color: expiryColor,
                      fontSize: 12,
                      fontWeight: countdownBadge && doc.expiresAt != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminderStatus,
                    style: TextStyle(
                      color: remindersOn
                          ? const Color(0xFF86EFAC)
                          : Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ειδοποίηση για αυτή την κάρτα',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Switch(
                        key: index == 0 ? tourSwitchKey : null,
                        value: doc.remindersEnabled,
                        onChanged: (value) =>
                            onToggleDocumentReminders(index, value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        key: index == 0 ? tourDateButtonKey : null,
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
                      if (ocrSupported && hasImage)
                        OutlinedButton.icon(
                          onPressed: () => onScanDate(index),
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Ανάγνωση'),
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

}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.onToggleNotifications,
    required this.notificationsEnabled,
    required this.reminderDays,
    required this.onReminderDaysChanged,
    required this.countdownBadge,
    required this.onToggleCountdownBadge,
    required this.onShowFeatureTour,
    this.notificationsTourKey,
  });

  final ValueChanged<bool> onToggleNotifications;
  final bool notificationsEnabled;
  final int reminderDays;
  final ValueChanged<int> onReminderDaysChanged;
  final bool countdownBadge;
  final ValueChanged<bool> onToggleCountdownBadge;
  final VoidCallback onShowFeatureTour;
  final Key? notificationsTourKey;
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
          key: notificationsTourKey,
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
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => _showReminderDaysDialog(context),
            child: Text('$reminderDays'),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.timer_outlined,
          title: 'Αντίστροφη μέτρηση λήξης',
          subtitle:
              'Εμφάνιση «Λήγει σε X μέρες» (κόκκινο αν < 30 ημέρες).',
          trailing: Switch(
            value: countdownBadge,
            onChanged: onToggleCountdownBadge,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.school_outlined,
          title: 'Οδηγός εφαρμογής',
          subtitle: 'Εμφάνιση ξανά του διαδραστικού οδηγού με βέλη.',
          onTap: onShowFeatureTour,
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
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
              hintText: 'π.χ. 30',
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
    super.key,
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
      key: key,
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
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
