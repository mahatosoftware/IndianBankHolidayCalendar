import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/holiday_item.dart';

class HolidayRepository {
  Future<List<HolidayItem>> fetchHolidays(int year) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/$year.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> data = jsonData['data'];
      return data.map((e) => HolidayItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load holidays for $year: $e');
    }
  }
}
