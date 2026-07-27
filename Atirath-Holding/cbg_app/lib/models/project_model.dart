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
  final String? leadLagStatus;

  // Additional helper fields used by the dashboard
  final String? _name;
  final String? _details;
  final String? _role;
  final int? _assigned;
  final int? _open;
  final int? _inProgress;
  final double? _progressValue;
  final String? _progressText;
  final Color? _barColor;
  final String? companyName;
  final String? plantName;
  final String? location;
  final String? _leadLagStatus;

  String get name => _name ?? prjNm;
  String get details => _details ?? prjDesc;
  String get role => _role ?? 'Assignee';
  int get assigned => _assigned ?? 0;
  int get open => _open ?? 0;
  int get inProgress => _inProgress ?? 0;
  int get closed => assigned - open;
  double get progressValue => _progressValue ?? 0.0;
  String get progressText => _progressText ?? '0%';
  Color get barColor {
    if (_barColor != null) return _barColor;
    final double val = progressValue;
    if (val < 0.5) {
      return const Color(0xffF97316); // Orange for < 50%
    } else if (val < 1.0) {
      return const Color(0xff3B82F6); // Blue for >= 50% and < 100%
    } else {
      return const Color(0xff22C55E); // Green for 100%
    }
  }
  String get leadLagStatusStr => _leadLagStatus ?? leadLagStatus ?? 'Lag';
  
  double? get rawProgressValue => _progressValue;
  int? get rawAssigned => _assigned;
  int? get rawOpen => _open;
  int? get rawInProgress => _inProgress;

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
    this.leadLagStatus,
    this.pltId = 0,
    this.coyId = 0,
    String? name,
    String? details,
    String? role,
    int? assigned,
    int? open,
    int? inProgress,
    double? progressValue,
    String? progressText,
    Color? barColor,
    this.companyName,
    this.plantName,
    this.location,
    String? leadLagStatusStr,
  })  : _name = name,
        _details = details,
        _role = role,
        _assigned = assigned,
        _open = open,
        _inProgress = inProgress,
        _progressValue = progressValue,
        _progressText = progressText,
        _barColor = barColor,
        _leadLagStatus = leadLagStatusStr;

  final int? pltId;
  final int? coyId;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    int pltIdVal = parseToInt(json['pltId'] ?? json['plt_id'] ?? json['plantId']);
    if (pltIdVal == 0 && json['plant'] is Map) {
      pltIdVal = parseToInt(json['plant']['pltId'] ?? json['plant']['plt_id']);
    } else if (pltIdVal == 0 && json['plt'] is Map) {
      pltIdVal = parseToInt(json['plt']['pltId'] ?? json['plt']['plt_id']);
    }

    int coyIdVal = parseToInt(json['coyId'] ?? json['coy_id'] ?? json['companyId']);
    if (coyIdVal == 0 && json['company'] is Map) {
      coyIdVal = parseToInt(json['company']['coyId'] ?? json['company']['coy_id']);
    } else if (coyIdVal == 0 && json['coy'] is Map) {
      coyIdVal = parseToInt(json['coy']['coyId'] ?? json['coy']['coy_id']);
    }

    String? companyNameVal = json['clientName']?.toString() ?? 
                            json['coyNm']?.toString() ?? 
                            json['coy_nm']?.toString() ?? 
                            json['companyNm']?.toString() ?? 
                            json['companyName']?.toString();
    if (companyNameVal == null && json['company'] is Map) {
      companyNameVal = json['company']['clientName']?.toString() ?? json['company']['coyNm']?.toString() ?? json['company']['companyNm']?.toString() ?? json['company']['coyName']?.toString();
    } else if (companyNameVal == null && json['coy'] is Map) {
      companyNameVal = json['coy']['clientName']?.toString() ?? json['coy']['coyNm']?.toString() ?? json['coy']['companyNm']?.toString() ?? json['coy']['coyName']?.toString();
    }

    String? plantNameVal = json['pltNm']?.toString() ?? 
                          json['plt_nm']?.toString() ?? 
                          json['plantName']?.toString();
    if (plantNameVal == null && json['plant'] is Map) {
      plantNameVal = json['plant']['pltNm']?.toString() ?? json['plant']['plantName']?.toString();
    } else if (plantNameVal == null && json['plt'] is Map) {
      plantNameVal = json['plt']['pltNm']?.toString() ?? json['plt']['plantName']?.toString();
    }

    String? locationVal = json['location']?.toString() ?? 
                         json['addr']?.toString() ?? 
                         json['dist']?.toString();
    if (locationVal == null && json['plant'] is Map) {
      locationVal = json['plant']['addr']?.toString() ?? json['plant']['dist']?.toString() ?? json['plant']['location']?.toString();
    } else if (locationVal == null && json['plt'] is Map) {
      locationVal = json['plt']['addr']?.toString() ?? json['plt']['dist']?.toString() ?? json['plt']['location']?.toString();
    }

    final num? progressNum = json['progress'] ?? json['projectProgress'] ?? json['prjProgress'] ?? json['progressValue'] ?? json['progress_value'];
    double? progressVal;
    String? progressTxt;
    Color? barColorVal;
    if (progressNum != null) {
      final double rawVal = progressNum.toDouble();
      progressVal = rawVal > 1.0 ? rawVal / 100.0 : rawVal;
      progressTxt = '${(progressVal * 100).round()}%';
      if (progressVal < 0.5) {
        barColorVal = const Color(0xffF97316);
      } else if (progressVal < 1.0) {
        barColorVal = const Color(0xff3B82F6);
      } else {
        barColorVal = const Color(0xff22C55E);
      }
    }

    final String? roleVal = json['role']?.toString();
    final int? assignedVal = (json['assigned'] ?? json['tasksAssigned'] ?? json['tasks_assigned'] ?? json['noOfTasksAssigned'] ?? json['assignedTasks']) != null
        ? parseToInt(json['assigned'] ?? json['tasksAssigned'] ?? json['tasks_assigned'] ?? json['noOfTasksAssigned'] ?? json['assignedTasks'])
        : null;
    final int? openVal = (json['open'] ?? json['openTasks'] ?? json['open_tasks'] ?? json['noOfOpenTasks'] ?? json['openTasksCount']) != null
        ? parseToInt(json['open'] ?? json['openTasks'] ?? json['open_tasks'] ?? json['noOfOpenTasks'] ?? json['openTasksCount'])
        : null;
    final int? inProgressVal = (json['inProgress'] ?? json['in_progress'] ?? json['inProgressTasks'] ?? json['in_progress_tasks']) != null
        ? parseToInt(json['inProgress'] ?? json['in_progress'] ?? json['inProgressTasks'] ?? json['in_progress_tasks'])
        : null;

    return ProjectModel(
      prjId: parseToInt(json['prjId'] ?? json['prj_id'] ?? json['projectId']),
      prjCd: json['prjCd']?.toString() ?? json['prj_cd']?.toString() ?? json['projectCode']?.toString() ?? '',
      prjNm: json['prjNm']?.toString() ?? json['prj_nm']?.toString() ?? json['projectName']?.toString() ?? '',
      prjDesc: json['prjDesc']?.toString() ?? json['prj_desc']?.toString() ?? json['projectDesc']?.toString() ?? json['description']?.toString() ?? '',
      prjPrty: json['prjPrty']?.toString() ?? json['prj_prty']?.toString() ?? json['projectPriority']?.toString() ?? json['priority']?.toString() ?? '',
      prjSts: json['prjSts']?.toString() ?? json['prj_sts']?.toString() ?? json['projectStatus']?.toString() ?? json['status']?.toString() ?? '',
      stDt: json['stDt']?.toString() ?? json['st_dt']?.toString() ?? json['startDate']?.toString() ?? json['start_date']?.toString() ?? '',
      endDt: json['endDt']?.toString() ?? json['end_dt']?.toString() ?? json['endDate']?.toString() ?? json['end_date']?.toString() ?? '',
      noOfDays: parseToInt(json['noOfDays'] ?? json['no_of_days'] ?? json['duration']),
      logo: json['logo']?.toString(),
      addlRem: (json['addlRem'] ?? json['addl_rem'])?.toString(),
      leadLagStatus: json['leadLagStatus']?.toString(),
      pltId: pltIdVal,
      coyId: coyIdVal,
      companyName: companyNameVal,
      plantName: plantNameVal,
      location: locationVal,
      role: roleVal,
      assigned: assignedVal,
      open: openVal,
      inProgress: inProgressVal,
      progressValue: progressVal,
      progressText: progressTxt,
      barColor: barColorVal,
    );
  }
}