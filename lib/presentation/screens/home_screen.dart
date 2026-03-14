import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers.dart';
import '../widgets/holiday_calendar_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/choice'),
        ),
        title: const Text(
          'Indian Bank Holiday Calendar',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => SystemNavigator.pop(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
          ),
          child: Column(
            children: [
              _buildSearchAndFilters(context, ref),
              const HolidayCalendarView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2x2 Filters Grid
          _buildFiltersGrid(context, ref),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                ref.read(selectedYearProvider.notifier).updateState(DateTime.now().year);
                ref.read(selectedMonthProvider.notifier).updateState(DateTime.now().month);
                ref.read(selectedStateProvider.notifier).updateState(null);
                ref.read(selectedRegionProvider.notifier).updateState(null);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset Filters'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersGrid(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(availableYearsProvider);
    final years = yearsAsync.value ?? [DateTime.now().year];

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final states = ref.watch(availableStatesProvider);
    final regions = ref.watch(availableRegionsProvider);

    final selectedYear = ref.watch(selectedYearProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedState = ref.watch(selectedStateProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown<int>(
                context: context,
                label: 'Year',
                value: years.contains(selectedYear) ? selectedYear : years.first,
                items: years.map((y) {
                  return DropdownMenuItem(
                    value: y,
                    child: Text(y.toString(),
                        style: TextStyle(
                          fontWeight: y == selectedYear ? FontWeight.bold : FontWeight.normal,
                        )),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedYearProvider.notifier).updateState(val);
                  }
                },
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildDropdown<int?>(
                context: context,
                label: 'Month',
                value: selectedMonth,
                items: [
                  DropdownMenuItem(
                      value: null,
                      child: Text('All',
                          style: TextStyle(
                              fontWeight: selectedMonth == null
                                  ? FontWeight.bold
                                  : FontWeight.normal))),
                  ...months.asMap().entries.map((entry) {
                    final val = entry.key + 1;
                    return DropdownMenuItem(
                      value: val,
                      child: Text(entry.value,
                          style: TextStyle(
                              fontWeight: selectedMonth == val
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    );
                  }),
                ],
                onChanged: (val) {
                  ref.read(selectedMonthProvider.notifier).updateState(val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildDropdown<String?>(
                context: context,
                label: 'State',
                value: selectedState,
                items: [
                  DropdownMenuItem(
                      value: null,
                      child: Text('All',
                          style: TextStyle(
                              fontWeight: selectedState == null
                                  ? FontWeight.bold
                                  : FontWeight.normal))),
                  ...states.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: selectedState == s
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    );
                  }),
                ],
                onChanged: (val) {
                  ref.read(selectedStateProvider.notifier).updateState(val);
                  ref.read(selectedRegionProvider.notifier).updateState(null);
                },
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildDropdown<String?>(
                context: context,
                label: 'Region',
                value: selectedRegion,
                items: [
                  DropdownMenuItem(
                      value: null,
                      child: Text('All',
                          style: TextStyle(
                              fontWeight: selectedRegion == null
                                  ? FontWeight.bold
                                  : FontWeight.normal))),
                  ...regions.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(r,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: selectedRegion == r
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    );
                  }),
                ],
                onChanged: (val) {
                  ref.read(selectedRegionProvider.notifier).updateState(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
      borderRadius: BorderRadius.circular(12),
    );
  }
}
