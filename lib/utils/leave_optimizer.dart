import '../data/models/holiday_item.dart';

class LeaveSuggestion {
  final DateTime startDate;
  final DateTime endDate;
  final int totalDaysOff;
  final List<DateTime> requiredLeaveDays;
  final List<HolidayItem> includedHolidays;

  LeaveSuggestion({
    required this.startDate,
    required this.endDate,
    required this.totalDaysOff,
    required this.requiredLeaveDays,
    required this.includedHolidays,
  });
}

class LeaveOptimizer {
  final List<HolidayItem> holidays;
  final int year;

  LeaveOptimizer({required this.holidays, required this.year});

  bool isWeekend(DateTime date) {
    if (date.weekday == DateTime.sunday) return true;
    if (date.weekday == DateTime.saturday) {
      // Consider 2nd and 4th Saturdays as bank holidays (typical standard)
      int order = (date.day - 1) ~/ 7 + 1;
      if (order == 2 || order == 4) return true;
    }
    return false;
  }

  HolidayItem? getHoliday(DateTime date) {
    for (var h in holidays) {
      if (h.date.year == date.year &&
          h.date.month == date.month &&
          h.date.day == date.day) {
        return h;
      }
    }
    return null;
  }

  bool isOffDay(DateTime date) {
    return isWeekend(date) || getHoliday(date) != null;
  }

  List<LeaveSuggestion> suggestLeaves(int leaveDaysWanted) {
    List<LeaveSuggestion> suggestions = [];
    DateTime startOfYear = DateTime(year, 1, 1);
    DateTime endOfYear = DateTime(year, 12, 31);

    int totalDaysInYear = endOfYear.difference(startOfYear).inDays + 1;
    List<DateTime> days = List.generate(
      totalDaysInYear,
      (i) => startOfYear.add(Duration(days: i)),
    );

    List<bool> offDays = days.map((d) => isOffDay(d)).toList();

    for (int startIdx = 0; startIdx < totalDaysInYear; startIdx++) {
      // Skip if the previous day was also off, to ensure we only get maximal continuous blocks
      if (startIdx > 0 && offDays[startIdx - 1]) continue;

      int workingDaysEncountered = 0;
      int endIdx = startIdx;
      List<DateTime> requiredLeaveDays = [];
      List<HolidayItem> includedHolidays = [];

      while (endIdx < totalDaysInYear) {
        if (!offDays[endIdx]) {
          if (workingDaysEncountered == leaveDaysWanted) {
            break; // Stop if we have hit the maximum requested leave days
          }
          workingDaysEncountered++;
          requiredLeaveDays.add(days[endIdx]);
        } else {
          var holiday = getHoliday(days[endIdx]);
          if (holiday != null) includedHolidays.add(holiday);
        }
        endIdx++;
      }

      int actualEndIdx = endIdx - 1;
      int totalDaysOff = actualEndIdx - startIdx + 1;

      bool overlapsRestrictedDays = false;
      for (int i = startIdx; i <= actualEndIdx; i++) {
        var d = days[i];
        if ((d.month == 3 && d.day == 31) || (d.month == 4 && d.day == 1)) {
          overlapsRestrictedDays = true;
          break;
        }
      }

      // Only add suggestions if we actually have meaningful time off (greater than the leave taking itself)
      // and it does not overlap with a restricted day (March 31, April 1) since bankers must be present for closing.
      if (totalDaysOff > leaveDaysWanted && !overlapsRestrictedDays) {
        suggestions.add(LeaveSuggestion(
          startDate: days[startIdx],
          endDate: days[actualEndIdx],
          totalDaysOff: totalDaysOff,
          requiredLeaveDays: requiredLeaveDays,
          includedHolidays: includedHolidays,
        ));
      }
    }

    // Sort descending by highest total days off
    suggestions.sort((a, b) => b.totalDaysOff.compareTo(a.totalDaysOff));

    return suggestions;
  }
}
