import 'package:flutter/material.dart';

const primary = Color(0xff0E21A2);
const secondary = Color(0Xffeec643);
var darkPrimary = Color(0xff001638);
var black = const Color(0xff141414);
var white = const Color(0xffeff0f2);
var grey = const Color(0xffB3B3B3);
TimeOfDay parseTime(String timeString) {
  List<String> parts = timeString.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
