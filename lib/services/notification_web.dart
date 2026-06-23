// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> requestPermission() async {
  if (!html.Notification.supported) {
    return false;
  }
  if (html.Notification.permission == 'granted') {
    return true;
  }
  final permission = await html.Notification.requestPermission();
  return permission == 'granted';
}

Future<bool> showNotification({
  required String title,
  required String body,
}) async {
  if (!html.Notification.supported) {
    return false;
  }
  if (html.Notification.permission != 'granted') {
    return false;
  }
  html.Notification(title, body: body);
  return true;
}
