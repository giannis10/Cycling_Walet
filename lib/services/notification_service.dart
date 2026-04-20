import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_web_stub.dart'
    if (dart.library.html) 'notification_web.dart' as web;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const String _enabledKey = 'notifications_enabled';

  static const String _channelId = 'reminders';
  static const String _channelName = 'Υπενθυμίσεις';
  static const String _channelDescription = 'Ειδοποιήσεις εφαρμογής';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _enabled = true;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    if (kIsWeb) {
      return;
    }

    tz.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    await _createChannel();
    await _requestPermissions();
  }

  Future<bool> showTestNotification() async {
    if (kIsWeb) {
      final allowed = await web.requestPermission();
      if (!allowed) {
        return false;
      }
      return web.showNotification(
        title: 'Cycling Wallet',
        body: 'Δοκιμαστική ειδοποίηση',
      );
    }
    if (!_enabled) {
      return false;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      0,
      'Cycling Wallet',
      'Δοκιμαστική ειδοποίηση',
      details,
    );
    return true;
  }

  Future<bool> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      final allowed = await web.requestPermission();
      if (!allowed) {
        return false;
      }
      return web.showNotification(title: title, body: body);
    }
    if (!_enabled) {
      return false;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _plugin.show(id, title, body, details);
    return true;
  }

  Future<void> scheduleExpiryNotification({
    required int id,
    required DateTime date,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }
    if (!_enabled) {
      await _plugin.cancel(id);
      return;
    }

    final scheduledDate = tz.TZDateTime.from(
      DateTime(date.year, date.month, date.day, 9),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancel(id);
  }

  bool get enabled => _enabled;

  Future<bool> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!value) {
      _enabled = false;
      await prefs.setBool(_enabledKey, false);
      if (!kIsWeb) {
        await _plugin.cancelAll();
      }
      return false;
    }

    bool granted = true;
    if (kIsWeb) {
      granted = await web.requestPermission();
      _enabled = granted;
      await prefs.setBool(_enabledKey, granted);
      return granted;
    } else {
      final androidGranted = await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          true;
      final iosGranted = await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
      final macGranted = await _plugin
              .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
      granted = androidGranted && iosGranted && macGranted;
    }

    _enabled = granted;
    await prefs.setBool(_enabledKey, granted);
    if (!granted) {
      await _plugin.cancelAll();
    }
    return granted;
  }

  Future<void> _createChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await android.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
