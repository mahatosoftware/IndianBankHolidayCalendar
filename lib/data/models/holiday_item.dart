import 'package:json_annotation/json_annotation.dart';

part 'holiday_item.g.dart';

@JsonSerializable(createToJson: false)
class HolidayItem {
  @JsonKey(name: 'state')
  final String state;

  @JsonKey(name: 'region')
  final String region;

  @JsonKey(name: 'holiday_name')
  final String holidayName;

  @JsonKey(name: 'date')
  final DateTime date;

  HolidayItem({
    required this.state,
    required this.region,
    required this.holidayName,
    required this.date,
  });

  factory HolidayItem.fromJson(Map<String, dynamic> json) =>
      _$HolidayItemFromJson(json);
}
