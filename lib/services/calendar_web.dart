import 'dart:convert';
import 'dart:html' as html;

Future<bool> downloadIcs({
  required String title,
  required String body,
  required DateTime start,
  required DateTime end,
}) async {
  final content = _buildIcs(title: title, body: body, start: start, end: end);
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/calendar;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = 'cycling_wallet_event.ics'
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}

String _buildIcs({
  required String title,
  required String body,
  required DateTime start,
  required DateTime end,
}) {
  final uid = '${DateTime.now().millisecondsSinceEpoch}@cyclingwallet';
  final dtStamp = _formatUtc(DateTime.now());
  final dtStart = _formatLocal(start);
  final dtEnd = _formatLocal(end);
  final safeTitle = _escape(title);
  final safeBody = _escape(body);

  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Cycling Wallet//EN',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    'UID:$uid',
    'DTSTAMP:$dtStamp',
    'DTSTART:$dtStart',
    'DTEND:$dtEnd',
    'SUMMARY:$safeTitle',
    'DESCRIPTION:$safeBody',
    'BEGIN:VALARM',
    'TRIGGER:-PT0M',
    'ACTION:DISPLAY',
    'DESCRIPTION:$safeBody',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
}

String _formatUtc(DateTime date) {
  final dt = date.toUtc();
  return _format(dt) + 'Z';
}

String _formatLocal(DateTime date) {
  return _format(date);
}

String _format(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  final s = date.second.toString().padLeft(2, '0');
  return '${y}${m}${d}T${h}${min}${s}';
}

String _escape(String value) {
  return value
      .replaceAll('\\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;');
}
