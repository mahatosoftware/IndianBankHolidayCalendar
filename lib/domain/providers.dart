import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/holiday_item.dart';
import '../data/repository/holiday_repository.dart';

final holidayRepositoryProvider = Provider((ref) => HolidayRepository());

final availableYearsProvider = FutureProvider<List<int>>((ref) async {
  try {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final years = manifestMap.keys
        .map((key) {
          final match = RegExp(r'assets/(\d{4})\.json').firstMatch(key);
          return match != null ? int.parse(match.group(1)!) : null;
        })
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    if (years.isNotEmpty) return years;
  } catch (e) {
    // fallback
  }
  return [DateTime.now().year];
});

class SelectedYearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  void updateState(int val) => state = val;
}
final selectedYearProvider = NotifierProvider<SelectedYearNotifier, int>(SelectedYearNotifier.new);

class SelectedMonthNotifier extends Notifier<int?> {
  @override
  int? build() => DateTime.now().month;
  void updateState(int? val) => state = val;
}
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, int?>(SelectedMonthNotifier.new);

final holidaysFutureProvider = FutureProvider<List<HolidayItem>>((ref) async {
  final repo = ref.watch(holidayRepositoryProvider);
  final year = ref.watch(selectedYearProvider);
  return repo.fetchHolidays(year);
});

class SelectedStateNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void updateState(String? val) => state = val;
}
final selectedStateProvider = NotifierProvider<SelectedStateNotifier, String?>(SelectedStateNotifier.new);

class SelectedRegionNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void updateState(String? val) => state = val;
}
final selectedRegionProvider = NotifierProvider<SelectedRegionNotifier, String?>(SelectedRegionNotifier.new);

final filteredHolidaysProvider = Provider<AsyncValue<List<HolidayItem>>>((ref) {
  final holidaysAsyncValue = ref.watch(holidaysFutureProvider);

  return holidaysAsyncValue.whenData((holidays) {
    var list = holidays.toList();

    final month = ref.watch(selectedMonthProvider);
    if (month != null) {
      list = list.where((item) => item.date.month == month).toList();
    }

    final state = ref.watch(selectedStateProvider);
    if (state != null && state != 'All') {
      list = list.where((item) => item.state == state).toList();
    }

    final region = ref.watch(selectedRegionProvider);
    if (region != null && region != 'All') {
      list = list.where((item) => item.region == region).toList();
    }

    // Sort by Date
    list.sort((a, b) => a.date.compareTo(b.date));

    return list;
  });
});

final availableStatesProvider = Provider<List<String>>((ref) {
  final holidaysAsyncValue = ref.watch(holidaysFutureProvider);
  return holidaysAsyncValue.maybeWhen(
    data: (holidays) => holidays.map((e) => e.state).toSet().toList()..sort(),
    orElse: () => [],
  );
});

final availableRegionsProvider = Provider<List<String>>((ref) {
  final holidaysAsyncValue = ref.watch(holidaysFutureProvider);
  final selectedState = ref.watch(selectedStateProvider);

  return holidaysAsyncValue.maybeWhen(
    data: (holidays) {
      var filtered = holidays.toList();
      if (selectedState != null && selectedState != 'All') {
        filtered = filtered.where((e) => e.state == selectedState).toList();
      }
      return filtered.map((e) => e.region).toSet().toList()..sort();
    },
    orElse: () => [],
  );
});
