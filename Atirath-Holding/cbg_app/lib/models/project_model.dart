import 'package:flutter/material.dart';

class ProjectModel {
  final int prjId;
  final String prjCd;
  final String prjNm;
  final String prjDesc;
  final String prjPrty;
  final String prjSts;
  final String stDt;
  final String endDt;
  final  int noOfDays;
  final String? logo;
  final String? addlRem;

  // Additional helper fields used by the dashboard
  final String? _name;
  final String? _details;
  final String? _role;
  final int? _assigned;
  final int? _open;
  final double? _progressValue;
  final String? _progressText;
  final Color? _barColor;

  String get name => _name ?? prjNm;
  String get details => _details ?? prjDesc;
  String get role => _role ?? 'Assignee';
  int get assigned => _assigned ?? 0;
  int get open => _open ?? 0;
  double get progressValue => _progressValue ?? 0.0;
  String get progressText => _progressText ?? '0%';
  Color get barColor => _barColor ?? const Color(0xFF10B981);

  ProjectModel({
    this.prjId = 0,
    this.prjCd = '',
    this.prjNm = '',
    this.prjDesc = '',
    this.prjPrty = '',
    this.prjSts = '',
    this.stDt = '',
    this.endDt = '',
    this.noOfDays = 0,
    this.logo,
    this.addlRem,
    this.pltId = 0,
    String? name,
    String? details,
    String? role,
    int? assigned,
    int? open,
    double? progressValue,
    String? progressText,
    Color? barColor,
  })  : _name = name,
        _details = details,
        _role = role,
        _assigned = assigned,
        _open = open,
        _progressValue = progressValue,
        _progressText = progressText,
        _barColor = barColor;

  final int? pltId;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      prjId: json['prjId'] ?? 0,
      prjCd: json['prjCd'] ?? '',
      prjNm: json['prjNm'] ?? '',
      prjDesc: json['prjDesc'] ?? '',
      prjPrty: json['prjPrty'] ?? '',
      prjSts: json['prjSts'] ?? '',
      stDt: json['stDt'] ?? '',
      endDt: json['endDt'] ?? '',
      noOfDays: json['noOfDays'] ?? 0,
      logo: json['logo'],
      addlRem: json['addlRem'] ?? json['addl_rem'],
      pltId: json['pltId'] ?? json['plt_id'] ?? 0,
    );
  }
}