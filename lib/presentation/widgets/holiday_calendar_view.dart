import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/holiday_item.dart';
import '../../domain/providers.dart';
import 'holiday_card.dart';

class HolidayCalendarView extends ConsumerStatefulWidget {
  const HolidayCalendarView({super.key});

  @override
  ConsumerState<HolidayCalendarView> createState() => _HolidayCalendarViewState();
}

class _HolidayCalendarViewState extends ConsumerState<HolidayCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(selectedMonthProvider, (previous, next) {
      if (next != null) {
        setState(() {
          _focusedDay = DateTime(_focusedDay.year, next, 1);
        });
      }
    });

    ref.listen<int>(selectedYearProvider, (previous, next) {
      setState(() {
         _focusedDay = DateTime(next, _focusedDay.month, 1);
      });
    });

    final holidaysAsync = ref.watch(filteredHolidaysProvider);

    return holidaysAsync.when(
      data: (holidays) {
        // Group holidays by date
        final Map<DateTime, List<HolidayItem>> groupedHolidays = {};
        for (var holiday in holidays) {
          // Normalize date to remove time portions
          final normalizedDate = DateTime(
            holiday.date.year,
            holiday.date.month,
            holiday.date.day,
          );
          if (groupedHolidays.containsKey(normalizedDate)) {
            groupedHolidays[normalizedDate]!.add(holiday);
          } else {
            groupedHolidays[normalizedDate] = [holiday];
          }
        }

        final selectedHolidays = _selectedDay != null 
            ? (groupedHolidays[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? []) 
            : <HolidayItem>[];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TableCalendar<HolidayItem>(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rowHeight: 48, // Reduced slightly to prevent large device pixel ratio overflow
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = selectedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  final availableYearsAsync = ref.read(availableYearsProvider);
                  final availableYears = availableYearsAsync.value ?? [DateTime.now().year];
                  final currentYear = ref.read(selectedYearProvider);

                  var targetDay = focusedDay;

                  if (!availableYears.contains(focusedDay.year)) {
                    if (focusedDay.year > currentYear) {
                      // Next year is not available, cycle back to January of the current year
                      targetDay = DateTime(currentYear, 1, 1);
                    } else if (focusedDay.year < currentYear) {
                      // Previous year is not available, cycle to December of the current year
                      targetDay = DateTime(currentYear, 12, 1);
                    }
                  }

                  setState(() {
                    _focusedDay = targetDay;
                  });
                  
                  Future.microtask(() {
                    ref.read(selectedMonthProvider.notifier).updateState(targetDay.month);
                    ref.read(selectedYearProvider.notifier).updateState(targetDay.year);
                  });
                },
                eventLoader: (day) {
                  final normalizedDate = DateTime(day.year, day.month, day.day);
                  return groupedHolidays[normalizedDate] ?? [];
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  holidayDecoration: const BoxDecoration(),
                  holidayTextStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.blue, 
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  outsideDaysVisible: false,
                ),
                holidayPredicate: (day) {
                  final normalizedDate = DateTime(day.year, day.month, day.day);
                  return groupedHolidays.containsKey(normalizedDate);
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                  titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedDay != null)
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 32),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedHolidays.length,
                itemBuilder: (context, index) {
                  return HolidayCard(holiday: selectedHolidays[index]);
                },
              ),
            if (_selectedDay == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 32, top: 16),
                child: Center(
                  child: Text(
                    'Select a day to view holidays',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        );

      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Error loading data')),
    );
  }
}
