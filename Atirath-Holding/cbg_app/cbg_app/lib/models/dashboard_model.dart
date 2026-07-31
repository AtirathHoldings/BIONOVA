import 'package:flutter/material.dart';

class DashboardModel {
  final String name;
  final String details;
  final String role;
  final int assigned;
  final int open;
  final double progressValue;
  final String progressText;
  final Color barColor;

  DashboardModel({
    required this.name,
    required this.details,
    required this.role,
    required this.assigned,
    required this.open,
    required this.progressValue,
    required this.progressText,
    required this.barColor,
  });
}