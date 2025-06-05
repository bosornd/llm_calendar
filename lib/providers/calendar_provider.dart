import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<DateTime, List<CalendarEvent>> _events = {};

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;
  Map<DateTime, List<CalendarEvent>> get events => _events;

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  void setSelectedDay(DateTime? day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  void addEvent(DateTime date, CalendarEvent event) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (_events[normalizedDate] != null) {
      _events[normalizedDate]!.add(event);
    } else {
      _events[normalizedDate] = [event];
    }

    notifyListeners();
  }

  void removeEvent(DateTime date, CalendarEvent event) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _events[normalizedDate]?.remove(event);

    if (_events[normalizedDate]?.isEmpty == true) {
      _events.remove(normalizedDate);
    }

    notifyListeners();
  }

  void updateEvent(
    DateTime date,
    CalendarEvent oldEvent,
    CalendarEvent newEvent,
  ) {
    removeEvent(date, oldEvent);
    addEvent(date, newEvent);
  }
}
