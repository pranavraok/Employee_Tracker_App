import '../constants/app_constants.dart';
import 'dart:developer';

class WorkHoursService {
  // Check if current time is within work hours
  static bool isWithinWorkHours() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentWeekday = now.weekday;

    // Check if today is a work day
    if (!AppConstants.workDays.contains(currentWeekday)) {
      log('⏸️ Not a work day (${_getDayName(currentWeekday)})');
      return false;
    }

    // Check if current hour is within work hours
    if (currentHour >= AppConstants.workStartHour &&
        currentHour < AppConstants.workEndHour) {
      return true;
    }

    log('⏸️ Outside work hours ($currentHour:00)');
    return false;
  }

  // Get work status message
  static String getWorkStatusMessage() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentWeekday = now.weekday;

    if (!AppConstants.workDays.contains(currentWeekday)) {
      return 'Today is ${_getDayName(currentWeekday)} - Not a work day';
    }

    if (currentHour < AppConstants.workStartHour) {
      final hoursUntilStart = AppConstants.workStartHour - currentHour;
      return 'Work starts in $hoursUntilStart hours';
    }

    if (currentHour >= AppConstants.workEndHour) {
      return 'Work hours ended at ${AppConstants.workEndHour}:00';
    }

    return 'Tracking active';
  }

  // Get next work start time
  static DateTime getNextWorkStart() {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      AppConstants.workStartHour,
    );

    // If work already started today, check tomorrow
    if (now.hour >= AppConstants.workStartHour) {
      next = next.add(const Duration(days: 1));
    }

    // Skip to next work day if needed
    while (!AppConstants.workDays.contains(next.weekday)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  static String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}
