import 'package:add_2_calendar/add_2_calendar.dart' as add2;
import 'package:flutter/foundation.dart';

import 'calendar_web_stub.dart'
    if (dart.library.html) 'calendar_web.dart' as web;

class CalendarService {
  CalendarService._();

  static final CalendarService instance = CalendarService._();

  Future<bool> addExpiryEvent({
    required DateTime date,
    required String title,
  }) async {
    final start = DateTime(date.year, date.month, date.day, 9);
    final end = start.add(const Duration(hours: 1));
    final description = 'Υπενθύμιση λήξης για $title.';

    if (kIsWeb) {
      return web.downloadIcs(
        title: 'Λήξη: $title',
        body: description,
        start: start,
        end: end,
      );
    }

    final event = add2.Event(
      title: 'Λήξη: $title',
      description: description,
      startDate: start,
      endDate: end,
      iosParams: const add2.IOSParams(reminder: Duration(minutes: 0)),
    );
    return add2.Add2Calendar.addEvent2Cal(event);
  }
}
