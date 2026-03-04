import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers.dart';
import '../widgets/holiday_calendar_view.dart';
import '../../utils/leave_optimizer.dart';
import 'package:intl/intl.dart';

class BankerCalendarScreen extends ConsumerStatefulWidget {
  const BankerCalendarScreen({super.key});

  @override
  ConsumerState<BankerCalendarScreen> createState() => _BankerCalendarScreenState();
}

class _BankerCalendarScreenState extends ConsumerState<BankerCalendarScreen> {
  int _leaveDaysWanted = 2; // Default starting value

  @override
  Widget build(BuildContext context) {
    final selectedState = ref.watch(selectedStateProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final showInsights = (selectedState != null || selectedRegion != null) && selectedMonth != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Banker Holiday Optimizer',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
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
              if (showInsights) ...[
                const Divider(height: 32, thickness: 1),
                _buildOptimizerInsights(context, ref),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizerInsights(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysFutureProvider);
    final year = ref.watch(selectedYearProvider);
    final selectedState = ref.watch(selectedStateProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    
    return holidaysAsync.when(
      data: (holidays) {
        var filteredHolidays = holidays.toList();
        if (selectedState != null && selectedState != 'All') {
          filteredHolidays = filteredHolidays.where((item) => item.state == selectedState).toList();
        }
        if (selectedRegion != null && selectedRegion != 'All') {
          filteredHolidays = filteredHolidays.where((item) => item.region == selectedRegion).toList();
        }

        final optimizer = LeaveOptimizer(holidays: filteredHolidays, year: year);
        var suggestions = optimizer.suggestLeaves(_leaveDaysWanted);
        
        if (selectedMonth != null) {
          suggestions = suggestions.where((s) => s.startDate.month == selectedMonth || s.endDate.month == selectedMonth).toList();
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Leave Optimizer Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Desired Leave Days:',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                '$_leaveDaysWanted',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _leaveDaysWanted.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$_leaveDaysWanted',
                            onChanged: (val) {
                              setState(() {
                                _leaveDaysWanted = val.round();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (suggestions.isEmpty)
                         Text(
                          'No meaningful consecutive streaks found for $_leaveDaysWanted leave day(s) this year.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                         )
                      else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Top Suggestions for longest contiguous break:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Show Top 3 max
                        ...suggestions.take(3).map((suggestion) {
                          return _buildSuggestionTile(context, suggestion);
                        }),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const Center(child: Text('Failed to load leave insights')),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, LeaveSuggestion suggestion) {
    final dateFormat = DateFormat('MMM d');
    final durationFormat = DateFormat('MMM d, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${suggestion.totalDaysOff} Days Off',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(
                '${durationFormat.format(suggestion.startDate)} - ${dateFormat.format(suggestion.endDate)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
             'Take leaves on: ${suggestion.requiredLeaveDays.map((d) => dateFormat.format(d)).join(", ")}',
             style: const TextStyle(fontSize: 13),
          ),
          if (suggestion.includedHolidays.isNotEmpty) ...[
             const SizedBox(height: 4),
             Text(
               'Includes: ${suggestion.includedHolidays.map((h) => h.holidayName).toSet().join(", ")}',
               style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
             ),
          ]
        ],
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
