import 'package:flutter/material.dart';
import 'project_model.dart';

// ============================================================
// ✅ PRIORITY HELPERS
// ============================================================

IconData getPriorityIcon(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'low':
      return Icons.description_outlined;

    case 'normal':
      return Icons.layers;

    case 'medium':
      return Icons.gps_fixed; // target look

    case 'high':
      return Icons.flag;

    case 'critical':
      return Icons.warning_amber_outlined;

    case 'atmost critical':
    case 'at most critical': 
    case 'atmost_critical':
      return Icons.bolt_outlined;

    default:
      return Icons.description_outlined;
  }
}

Color getPriorityColor(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'low':
      return const Color(0xFF22C55E);

    case 'normal':
      return const Color(0xFF3B82F6);

    case 'medium':
      return const Color(0xFFF59E0B);

    case 'high':
      return const Color(0xFFEF4444);

    case 'critical':
      return const Color(0xFFB91C1C);

    case 'atmost critical':
    case 'at most critical':
    case 'atmost_critical':
      return const Color(0xFF7F1D1D);

    default:
      return const Color(0xFF3B82F6);
  }
}

Color getPriorityBg(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'low':
      return const Color(0xFFF0FDF4);

    case 'normal':
      return const Color(0xFFEFF6FF);

    case 'medium':
      return const Color(0xFFFFF7ED);

    case 'high':
      return const Color(0xFFFEF2F2);

    case 'critical':
      return const Color(0xFFFFF1F2);

    case 'atmost critical':
    case 'at most critical':
    case 'atmost_critical':
      return const Color(0xFFF5F3FF);

    default:
      return const Color(0xFFF8FAFC);
  }
}

// ============================================================
// ✅ TASK ITEM CLASS
// ============================================================

class TaskItem {
  static String parsePriorityFromBackend(Map<String, dynamic>? json) {
    if (json == null) return 'Normal';
    dynamic rawVal = json['priority'] ??
        json['priority_id'] ??
        json['priorityId'] ??
        json['priorityNm'] ??
        json['priority_nm'] ??
        json['taskPrty'] ??
        json['task_prty'] ??
        json['prty'] ??
        json['prtyId'] ??
        json['prty_id'] ??
        json['prjPrty'] ??
        json['prj_prty'] ??
        json['priority_level'] ??
        json['priorityLevel'];

    if (rawVal == null && json['task'] is Map) {
      rawVal = (json['task'] as Map)['priority'] ?? (json['task'] as Map)['taskPrty'];
    }

    if (rawVal == null && json['rawData'] is Map) {
      rawVal = (json['rawData'] as Map)['priority'] ?? (json['rawData'] as Map)['taskPrty'];
    }

    if (rawVal == null) return 'Normal';

    final String str = rawVal.toString().trim();
    if (str.isEmpty) return 'Normal';

    final String upper = str.toUpperCase();

    if (upper == '1' || upper == 'LOW') return 'Low';
    if (upper == '2' || upper == 'NORMAL') return 'Normal';
    if (upper == '3' || upper == 'MEDIUM') return 'Medium';
    if (upper == '4' || upper == 'HIGH') return 'High';
    if (upper == '5' || upper == 'CRITICAL') return 'Critical';
    if (upper == '6' || upper == 'ATMOST CRITICAL' || upper == 'AT MOST CRITICAL' || upper == 'ATMOST_CRITICAL') {
      return 'At Most Critical';
    }

    final formatted = str.split(RegExp(r'\s+|_')).map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ').trim();

    return formatted.isEmpty ? 'Normal' : formatted;
  }

  static String extractRawDate(Map<String, dynamic>? json, List<String> possibleKeys) {
    if (json == null) return '';
    for (final key in possibleKeys) {
      if (json[key] != null && json[key].toString().trim().isNotEmpty) {
        return json[key].toString().trim();
      }
    }
    return '';
  }

  static String getRawEndDate(Map<String, dynamic>? json) {
    return extractRawDate(json, [
      'endDt', 'end_dt', 'endDate', 'end_date',
      'targetDt', 'target_dt', 'targetDate', 'target_date',
      'dueDt', 'due_dt', 'dueDate', 'due_date',
      'taskEndDt', 'task_end_dt', 'complTargetDt', 'compl_target_dt'
    ]);
  }

  static String getRawStartDate(Map<String, dynamic>? json) {
    return extractRawDate(json, [
      'stDt', 'st_dt', 'startDate', 'start_date',
      'taskStDt', 'task_st_dt', 'createdDt', 'created_dt',
      'createdAt', 'created_at'
    ]);
  }

  static String getRawCompletionDate(Map<String, dynamic>? json) {
    return extractRawDate(json, [
      'compDt', 'comp_dt', 'completedDt', 'completed_dt',
      'actCmpDt', 'act_cmp_dt', 'actlEndDt', 'actl_end_dt',
      'updDt', 'upd_dt'
    ]);
  }

  static DateTime? parseDateTime(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;
    final str = rawDate.trim();

    try {
      return DateTime.parse(str);
    } catch (_) {}

    try {
      final cleanStr = str.split('T').first.split(' ').first;
      final delims = RegExp(r'[-/.]');
      if (cleanStr.contains(delims)) {
        final parts = cleanStr.split(delims);
        if (parts.length == 3) {
          int? p1 = int.tryParse(parts[0]);
          int? p2 = int.tryParse(parts[1]);
          int? p3 = int.tryParse(parts[2]);

          if (p1 != null && p2 != null && p3 != null) {
            if (p1 > 1000) {
              return DateTime(p1, p2, p3);
            } else if (p3 > 1000) {
              if (p2 <= 12) {
                return DateTime(p3, p2, p1);
              } else if (p1 <= 12) {
                return DateTime(p3, p1, p2);
              }
            }
          }
        }
      }
    } catch (_) {}

    try {
      final parts = str.replaceAll(',', '').split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        const months = {
          'jan': 1, 'january': 1,
          'feb': 2, 'february': 2,
          'mar': 3, 'march': 3,
          'apr': 4, 'april': 4,
          'may': 5,
          'jun': 6, 'june': 6,
          'jul': 7, 'july': 7,
          'aug': 8, 'august': 8,
          'sep': 9, 'september': 9,
          'oct': 10, 'october': 10,
          'nov': 11, 'november': 11,
          'dec': 12, 'december': 12,
        };
        int? day, month, year;
        final firstNum = int.tryParse(parts[0]);
        if (firstNum != null) {
          day = firstNum;
          month = months[parts[1].toLowerCase()];
          year = int.tryParse(parts[2]);
        } else {
          month = months[parts[0].toLowerCase()];
          day = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}

    return null;
  }

  static String formatDateStr(String? rawDate, {bool showToday = false}) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'No Date';
    final parsed = parseDateTime(rawDate);
    if (parsed == null) {
      if (rawDate.length <= 11 && !rawDate.contains('T')) {
        return rawDate;
      }
      return rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }

    final now = DateTime.now();
    if (showToday && parsed.year == now.year && parsed.month == now.month && parsed.day == now.day) {
      return 'Today';
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
  }

  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String status;
  final String priority;
  final String? timeStatus;
  final String? description;
  final String? reviewer;
  final String? approver;
  final String? drftTaskId;

  // Live context properties
  final String? projectName;
  final String? milestoneName;
  final String? projectRemarks;
  final String? milestoneRemarks;
  final String? taskRemarks;
  final String? startDate;
  final String? endDate;
  final String? rawStDt;
  final String? rawEndDt;

  // Individual Task context
  final bool isIndividualTask;
  final Map<String, dynamic>? rawData;

  // Project references
  final int? projectId;
  final String? projectCode;

  final bool isCurrentUserReviewer;
  final bool isCurrentUserApprover;

  const TaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.status,
    required this.priority,
    this.timeStatus,
    this.description,
    this.reviewer,
    this.approver,
    this.drftTaskId,
    this.projectName,
    this.milestoneName,
    this.projectRemarks,
    this.milestoneRemarks,
    this.taskRemarks,
    this.startDate,
    this.endDate,
    this.rawStDt,
    this.rawEndDt,
    this.isIndividualTask = false,
    this.rawData,
    this.projectId,
    this.projectCode,
    this.isCurrentUserReviewer = false,
    this.isCurrentUserApprover = false,
  });

  // ============================================================
  // ✅ FACTORY: fromIndividualTask - Complete corrected version
  // ============================================================
  factory TaskItem.fromIndividualTask(Map<String, dynamic> json, [String? currentEmpId]) {
    final String taskId = (json['empTaskId'] ?? json['emp_task_id'] ?? json['taskId'] ?? json['task_id'] ?? json['id'] ?? '0').toString();
    final String taskNm = json['taskNm'] ?? json['task_nm'] ?? json['taskName'] ?? json['task_name'] ?? json['title'] ?? 'Untitled';
    String dbStatus = '';
    final rawSts = json['taskSts'] ?? json['task_sts'] ?? json['status'] ?? json['taskStatus'] ?? json['task_status'] ?? json['sts'];
    if (rawSts != null) {
      if (rawSts is Map) {
        dbStatus = (rawSts['statusNm'] ?? rawSts['status_nm'] ?? rawSts['name'] ?? rawSts['statusId'] ?? '').toString();
      } else {
        dbStatus = rawSts.toString();
      }
    }
    if (dbStatus.isEmpty) dbStatus = 'OPEN';

    final String dbSubStatus = (json['subStatus'] ?? json['sub_status'] ?? json['prcsYesActn'] ?? json['prcs_yes_actn'] ?? json['prcsActn'] ?? json['prcs_actn'] ?? '').toString();
    
    final String reviewerId = json['reviewer']?.toString() ?? json['reviewerId']?.toString() ?? '';
    final String approverId = json['approver']?.toString() ?? json['approverId']?.toString() ?? '';
    final String assignerId = json['assignedBy']?.toString() ?? json['assigned_by']?.toString() ?? '';

    final bool isReviewer = currentEmpId != null && reviewerId == currentEmpId;
    final bool isApprover = currentEmpId != null && approverId == currentEmpId;

    final bool isAssigner = currentEmpId != null && assignerId == currentEmpId;
    final bool isDoer = currentEmpId != null && (json['empId']?.toString() == currentEmpId || json['empid']?.toString() == currentEmpId);

    List<String> roles = [];
    if (isDoer) roles.add('Executor');
    if (isReviewer) roles.add('Reviewer');
    if (isApprover) roles.add('Approver');
    if (isAssigner && !isDoer) roles.add('Assigned By Me');
    
    final String? taskDesc = json['taskDesc'] ?? json['task_desc'] ?? json['description'];
    
    final String normalizedStatus = dbStatus.toUpperCase().replaceAll('_', ' ').trim();
    final String normalizedSubStatus = dbSubStatus.toUpperCase().replaceAll('_', ' ').trim();
    final bool isClosedTask = 
        normalizedStatus.contains('CLOSED') || 
        normalizedStatus.contains('COMPLETED') || 
        normalizedStatus.contains('DONE') || 
        normalizedStatus.contains('FINISHED') ||
        dbStatus == '4' ||
        (rawSts is Map && (rawSts['statusId'] == 4 || rawSts['status_id'] == 4));

    final bool isUnderReviewTask = 
        normalizedStatus.contains('UNDER REVIEW') || 
        normalizedStatus.contains('SUBMIT REVIEW') || 
        normalizedStatus.contains('UNDER_REVIEW') || 
        normalizedStatus.contains('SUBMIT_REVIEW') || 
        normalizedStatus.contains('UNDERREVIEW') || 
        normalizedStatus.contains('SUBMITREVIEW') || 
        normalizedStatus.contains('PENDING REVIEW') || 
        normalizedSubStatus.contains('UNDER REVIEW') || 
        normalizedSubStatus.contains('SUBMIT REVIEW') || 
        normalizedSubStatus.contains('PENDING REVIEW') || 
        normalizedSubStatus.contains('PENDING REVIEWER') || 
        normalizedSubStatus.contains('PENDING APPROVER') ||
        dbStatus == '3' ||
        (rawSts is Map && (rawSts['statusId'] == 3 || rawSts['status_id'] == 3));

    // Status mapping
    String status = 'Open';
    if (isClosedTask) {
      status = 'Closed';
    } else if (isUnderReviewTask) {
      status = 'Under Review';
    } else if (normalizedStatus.contains('REASSIGN') || normalizedSubStatus.contains('REASSIGN')) {
      status = 'Reassigned';
    } else if (normalizedStatus.contains('REWORK') || normalizedSubStatus.contains('REWORK')) {
      status = 'Rework';
    } else if (normalizedStatus == 'WIP' || normalizedStatus == 'IN PROGRESS' || normalizedStatus == 'WORK IN PROGRESS') {
      status = 'In Progress';
    } else {
      status = 'Open';
    }

    // ============================================================
    // ✅ PRIORITY MAPPING FROM BACKEND DB
    // ============================================================
    final String priority = parsePriorityFromBackend(json);

    // ============================================================
    // ✅ PRIORITY-BASED ICON, COLORS, BADGE
    // ============================================================
    IconData icon = getPriorityIcon(priority);
    Color iconColor = getPriorityColor(priority);
    Color iconBg = getPriorityBg(priority);

    String tag = priority;
    Color tagColor = getPriorityColor(priority);
    Color tagBg = getPriorityBg(priority);
    
    // Process Icon override for specific statuses if needed
    if (status == 'Under Review') {
      icon = Icons.remove_red_eye_outlined;
      iconColor = const Color(0xFF8B5CF6);
      iconBg = const Color(0xFFF3E8FF);
    } else if (status == 'Rework') {
      icon = Icons.sync;
      iconColor = const Color(0xFFF97316);
      iconBg = const Color(0xFFFFF7ED);
    } else if (status == 'Reassigned') {
      icon = Icons.undo_rounded;
      iconColor = const Color(0xFF4F46E5);
      iconBg = const Color(0xFFEEF2FF);
    }

    final String rawEndDt = getRawEndDate(json);
    final String rawStDt = getRawStartDate(json);

    // Calculate timeStatus and overdue for individual tasks
    String? timeStatus;
    if (rawEndDt.isNotEmpty) {
      try {
        final parsed = parseDateTime(rawEndDt);
        if (parsed != null) {
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final endStart = DateTime(parsed.year, parsed.month, parsed.day);
          
          final bool isClosedTask = normalizedStatus.contains('CLOSED') ||
              normalizedStatus.contains('COMPLETED') ||
              normalizedStatus.contains('DONE') ||
              normalizedStatus.contains('FINISHED') ||
              (rawSts is Map && (rawSts['statusId'] == 4 || rawSts['status_id'] == 4)) ||
              dbStatus == '4';

          if (isClosedTask) {
             final rawAct = getRawCompletionDate(json);
             if (rawAct.isNotEmpty) {
               final parsedAct = parseDateTime(rawAct);
               if (parsedAct != null) {
                 final actStart = DateTime(parsedAct.year, parsedAct.month, parsedAct.day);
                 if (actStart.isBefore(endStart)) {
                   timeStatus = 'Lead';
                 } else if (actStart.isAfter(endStart)) {
                   timeStatus = 'Lag';
                 } else {
                   timeStatus = 'On Time';
                 }
               } else {
                 timeStatus = 'On Time';
               }
             } else {
               timeStatus = 'On Time';
             }
          } else {
             if (todayStart.isBefore(endStart)) {
                timeStatus = null;
             } else if (todayStart.isAtSameMomentAs(endStart)) {
                timeStatus = 'Due Today';
             } else {
                timeStatus = 'Overdue';
             }
          }
        }
      } catch (_) {}
    }

    String displayDate = formatDateStr(rawEndDt.isNotEmpty ? rawEndDt : rawStDt, showToday: true);
    String roleStr = roles.isNotEmpty ? 'Role: ${roles.join(', ')}' : 'Role: Unknown';

    return TaskItem(
      id: taskId,
      title: taskNm,
      subtitle: roleStr, // 👈 Show role in subtitle for individual task
      date: displayDate,
      tag: tag,
      tagColor: tagColor,
      tagBg: tagBg,
      icon: icon,
      iconColor: iconColor,
      iconBg: iconBg,
      status: status,
      priority: priority,
      timeStatus: timeStatus,
      description: taskDesc,
      reviewer: reviewerId,
      approver: approverId,
      startDate: rawStDt.isNotEmpty ? formatDateStr(rawStDt) : null,
      endDate: rawEndDt.isNotEmpty ? formatDateStr(rawEndDt) : null,
      rawStDt: rawStDt,
      rawEndDt: rawEndDt,
      taskRemarks: (json['remarks'] ?? json['noteTxt'] ?? json['note_txt'] ?? json['addlRem'] ?? json['addl_rem'])?.toString(),
      isIndividualTask: true,
      rawData: json,
      isCurrentUserReviewer: isReviewer,
      isCurrentUserApprover: isApprover,
    );
  }

  // ============================================================
  // ✅ FACTORY: fromJson - API Response నుండి TaskItem create చేయడానికి
  // ============================================================
  factory TaskItem.fromJson(
    Map<String, dynamic> json,
    ProjectModel project,
    Map<String, dynamic> milestone,
    [String? currentEmpId]
  ) {
    final String taskId = (json['taskId'] ?? json['task_id'] ?? json['empTaskId'] ?? json['emp_task_id'] ?? json['id'] ?? '0').toString();
    final String taskNm = json['taskNm'] ?? json['task_nm'] ?? json['taskName'] ?? json['task_name'] ?? json['title'] ?? '';
    final String? taskDesc = json['taskDesc'] ?? json['task_desc'] ?? json['description'];
    String dbStatus = '';
    final rawSts = json['taskSts'] ?? json['task_sts'] ?? json['status'] ?? json['taskStatus'] ?? json['task_status'] ?? json['sts'];
    if (rawSts != null) {
      if (rawSts is Map) {
        dbStatus = (rawSts['statusNm'] ?? rawSts['status_nm'] ?? rawSts['name'] ?? rawSts['statusId'] ?? '').toString();
      } else {
        dbStatus = rawSts.toString();
      }
    }
    if (dbStatus.isEmpty) dbStatus = 'OPEN';

    final String dbSubStatus = (json['subStatus'] ?? json['sub_status'] ?? json['prcsYesActn'] ?? json['prcs_yes_actn'] ?? json['prcsActn'] ?? json['prcs_actn'] ?? '').toString();

    final String dbReviewer = json['reviewer']?.toString() ?? '';
    final String dbApprover = json['approver']?.toString() ?? '';
    final bool isReviewer = currentEmpId != null && dbReviewer == currentEmpId.toString();
    final bool isApprover = currentEmpId != null && dbApprover == currentEmpId.toString();
    
    final String normalizedStatus = dbStatus.toUpperCase().replaceAll('_', ' ').trim();
    final String normalizedSubStatus = dbSubStatus.toUpperCase().replaceAll('_', ' ').trim();

    // Status mapping
    String status = 'Open';
    if (normalizedStatus.contains('CLOSED') || 
        normalizedStatus.contains('COMPLETED') || 
        normalizedStatus.contains('DONE') || 
        normalizedStatus.contains('FINISHED') ||
        (rawSts is Map && (rawSts['statusId'] == 4 || rawSts['status_id'] == 4))) {
      status = 'Closed';
    } 
    else if (normalizedSubStatus.contains('UNDER REVIEW') || 
             normalizedSubStatus.contains('SUBMIT REVIEW') || 
             normalizedSubStatus.contains('PENDING REVIEWER') || 
             normalizedSubStatus.contains('PENDING APPROVER')) {
      status = 'Under Review';
    } else if (normalizedSubStatus.contains('REASSIGN') || normalizedSubStatus.contains('REASSIGNED') || normalizedStatus.contains('REASSIGN')) {
      status = 'Reassigned';
    } else if (normalizedSubStatus.contains('REWORK') || normalizedStatus.contains('REWORK')) {
      status = 'Rework';
    } else if (normalizedStatus == 'WIP' || normalizedStatus == 'IN PROGRESS' || normalizedStatus == 'WORK IN PROGRESS') {
      status = 'In Progress';
    } else if (normalizedStatus == 'ASSIGNED' || normalizedStatus == 'OPEN' || normalizedStatus == 'PENDING' || normalizedStatus == 'DRAFT') {
      status = 'Open';
    } else {
      status = 'Open';
    }

    // Priority reading from backend (EXACT DB VALUE)
    final String priority = parsePriorityFromBackend(json);

    final String rawEndDt = getRawEndDate(json);
    final String rawStDt = getRawStartDate(json);

    // Due date calculation
    String dateStr = formatDateStr(rawEndDt.isNotEmpty ? rawEndDt : rawStDt, showToday: true);
    String? timeStatus;

    if (rawEndDt.isNotEmpty) {
      try {
        final parsed = parseDateTime(rawEndDt);
        if (parsed != null) {
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final endStart = DateTime(parsed.year, parsed.month, parsed.day);
          
          final bool isClosedTask2 = normalizedStatus.contains('CLOSED') ||
              normalizedStatus.contains('COMPLETED') ||
              normalizedStatus.contains('DONE') ||
              normalizedStatus.contains('FINISHED') ||
              (rawSts is Map && (rawSts['statusId'] == 4 || rawSts['status_id'] == 4)) ||
              dbStatus == '4';

          if (isClosedTask2) {
             final rawAct = getRawCompletionDate(json);
             if (rawAct.isNotEmpty) {
               final parsedAct = parseDateTime(rawAct);
               if (parsedAct != null) {
                 final actStart = DateTime(parsedAct.year, parsedAct.month, parsedAct.day);
                 if (actStart.isBefore(endStart)) {
                   timeStatus = 'Lead';
                 } else if (actStart.isAfter(endStart)) {
                   timeStatus = 'Lag';
                 } else {
                   timeStatus = 'On Time';
                 }
               } else {
                 timeStatus = 'On Time';
               }
             } else {
               timeStatus = 'On Time';
             }
          } else {
             if (todayStart.isBefore(endStart)) {
                timeStatus = null;
             } else if (todayStart.isAtSameMomentAs(endStart)) {
                timeStatus = 'Due Today';
             } else {
                timeStatus = 'Overdue';
             }
          }
        }
      } catch (_) {
        dateStr = rawEndDt;
      }
    }

    // Tag determination for normal tasks
    String tag = priority;
    Color tagColor = getPriorityColor(priority);
    Color tagBg = getPriorityBg(priority);

    // Default icon
    IconData icon = Icons.assignment_outlined;
    Color iconColor = const Color(0xFF3B82F6);
    Color iconBg = const Color(0xFFEFF6FF);
    
    if (status == 'Under Review') {
      icon = Icons.remove_red_eye_outlined;
      iconColor = const Color(0xFF8B5CF6);
      iconBg = const Color(0xFFF3E8FF);
    } else if (status == 'Rework') {
      icon = Icons.sync;
      iconColor = const Color(0xFFF97316);
      iconBg = const Color(0xFFFFF7ED);
    } else if (status == 'Reassigned') {
      icon = Icons.undo_rounded;
      iconColor = const Color(0xFF4F46E5);
      iconBg = const Color(0xFFEEF2FF);
    }

    return TaskItem(
      id: taskId,
      title: taskNm,
      subtitle: "${project.prjCd} • ${milestone['mlstnCd'] ?? 'MS'}",
      date: dateStr,
      tag: tag,
      tagColor: tagColor,
      tagBg: tagBg,
      icon: icon,
      iconColor: iconColor,
      iconBg: iconBg,
      status: status,
      priority: priority,
      timeStatus: timeStatus,
      description: taskDesc,
      reviewer: dbReviewer,
      approver: dbApprover,
      drftTaskId: json['drftTaskId']?.toString() ?? json['drft_task_id']?.toString(),
      projectName: project.prjNm.isNotEmpty ? project.prjNm : project.name,
      milestoneName: (milestone['mlstnTtl'] ?? milestone['title'] ?? '').toString(),
      projectRemarks: project.addlRem ?? project.prjDesc,
      milestoneRemarks: (milestone['addlRem'] ?? milestone['addl_rem'] ?? milestone['mlstnDesc'] ?? milestone['mlstn_desc'])?.toString(),
      taskRemarks: (json['addlRem'] ?? json['addl_rem'] ?? json['noteTxt'] ?? json['note_txt'])?.toString(),
      startDate: rawStDt.isNotEmpty ? formatDateStr(rawStDt) : null,
      endDate: rawEndDt.isNotEmpty ? formatDateStr(rawEndDt) : null,
      rawStDt: rawStDt,
      rawEndDt: rawEndDt,
      rawData: json,
      projectId: project.prjId,
      projectCode: project.prjCd,
      isCurrentUserReviewer: isReviewer,
      isCurrentUserApprover: isApprover,
    );
  }

  factory TaskItem.fromLiveTask(Map<String, dynamic> json, [String? currentEmpId]) {
    return TaskItem.fromJson(
      json,
      ProjectModel(
        prjId: 0, prjCd: '', prjNm: '', prjDesc: '', prjPrty: '', prjSts: '',
        stDt: '', endDt: '', noOfDays: 0, details: '', role: '', assigned: 0, open: 0,
        progressValue: 0.0, progressText: '', barColor: Colors.blue
      ),
      {},
      currentEmpId,
    );
  }

  // ============================================================
  // ✅ toJson - Local Storage కోసం Serialization
  // ============================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'date': date,
      'tag': tag,
      'tagColor': tagColor.toARGB32(),
      'tagBg': tagBg.toARGB32(),
      'icon': icon.codePoint,
      'iconColor': iconColor.toARGB32(),
      'iconBg': iconBg.toARGB32(),
      'status': status,
      'priority': priority,
      'description': description,
      'reviewer': reviewer,
      'approver': approver,
      'drftTaskId': drftTaskId,
      'projectName': projectName,
      'milestoneName': milestoneName,
      'projectRemarks': projectRemarks,
      'milestoneRemarks': milestoneRemarks,
      'taskRemarks': taskRemarks,
      'startDate': startDate,
      'endDate': endDate,
      'rawStDt': rawStDt,
      'rawEndDt': rawEndDt,
      'isIndividualTask': isIndividualTask,
      'rawData': rawData,
      'projectId': projectId,
      'projectCode': projectCode,
    };
  }

  // ============================================================
  // ✅ fromLocalJson - Local Storage నుండి Deserialization
  // ============================================================
  static IconData _getIconFromCodePoint(int codePoint) {
    if (codePoint == Icons.assignment_outlined.codePoint) return Icons.assignment_outlined;
    if (codePoint == Icons.shield_outlined.codePoint) return Icons.shield_outlined;
    if (codePoint == Icons.people_outline.codePoint) return Icons.people_outline;
    if (codePoint == Icons.description_outlined.codePoint) return Icons.description_outlined;
    if (codePoint == Icons.task_alt.codePoint) return Icons.task_alt;
    if (codePoint == Icons.warning_amber_rounded.codePoint) return Icons.warning_amber_rounded;
    if (codePoint == Icons.warning_amber_outlined.codePoint) return Icons.warning_amber_outlined;
    if (codePoint == Icons.flag.codePoint) return Icons.flag;
    if (codePoint == Icons.gps_fixed.codePoint) return Icons.gps_fixed;
    if (codePoint == Icons.layers.codePoint) return Icons.layers;
    if (codePoint == Icons.bolt_outlined.codePoint) return Icons.bolt_outlined;
    if (codePoint == Icons.undo.codePoint) return Icons.undo;
    return Icons.description_outlined;
  }

  factory TaskItem.fromLocalJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] ?? '0',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      date: json['date'] ?? '',
      tag: json['tag'] ?? '',
      tagColor: Color(json['tagColor'] ?? Colors.green.toARGB32()),
      tagBg: Color(json['tagBg'] ?? const Color(0xFFDCFCE7).toARGB32()),
      icon: _getIconFromCodePoint(json['icon'] ?? Icons.assignment_outlined.codePoint),
      iconColor: Color(json['iconColor'] ?? Colors.green.toARGB32()),
      iconBg: Color(json['iconBg'] ?? const Color(0xFFDCFCE7).toARGB32()),
      status: json['status'] ?? 'Open',
      priority: json['priority'] ?? 'Low',
      description: json['description'],
      reviewer: json['reviewer'],
      approver: json['approver'],
      drftTaskId: json['drftTaskId'],
      projectName: json['projectName'],
      milestoneName: json['milestoneName'],
      projectRemarks: json['projectRemarks'],
      milestoneRemarks: json['milestoneRemarks'],
      taskRemarks: json['taskRemarks'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      rawStDt: json['rawStDt'],
      rawEndDt: json['rawEndDt'],
      isIndividualTask: json['isIndividualTask'] ?? (json['subtitle'] == null || json['subtitle'].toString().trim().isEmpty),
      rawData: json['rawData'],
      projectId: json['projectId'],
      projectCode: json['projectCode'],
    );
  }

  // ============================================================
  // ✅ hasStarted - Task start ayindho ledho check చేయడానికి
  // ============================================================
  bool get hasStarted {
    if (isIndividualTask && (rawStDt == null || rawStDt!.isEmpty)) {
      return true; // Individual tasks without strict start dates should be active (To-Do)
    }
    if (rawStDt == null || rawStDt!.isEmpty) {
      return date == 'Today' || isOverdue;
    }
    try {
      final parsedStart = DateTime.parse(rawStDt!);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      return !parsedStart.isAfter(todayStart);
    } catch (_) {
      return true;
    }
  }

  bool get isOverdue => timeStatus == 'Overdue';

  String get taskCode {
    final code = (rawData?['taskCd'] ?? rawData?['task_cd'] ?? rawData?['taskCode'] ?? '').toString().trim();
    if (code.isNotEmpty) return code;
    return 'T-$id';
  }

  // ============================================================
  // ✅ copyWith - Immutable updates కోసం
  // ============================================================
  TaskItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? date,
    String? tag,
    Color? tagColor,
    Color? tagBg,
    IconData? icon,
    Color? iconColor,
    Color? iconBg,
    String? status,
    String? priority,
    String? description,
    String? reviewer,
    String? approver,
    String? drftTaskId,
    String? projectName,
    String? milestoneName,
    String? projectRemarks,
    String? milestoneRemarks,
    String? taskRemarks,
    String? startDate,
    String? endDate,
    String? rawStDt,
    String? rawEndDt,
    int? projectId,
    String? projectCode,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      tag: tag ?? this.tag,
      tagColor: tagColor ?? this.tagColor,
      tagBg: tagBg ?? this.tagBg,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBg: iconBg ?? this.iconBg,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      reviewer: reviewer ?? this.reviewer,
      approver: approver ?? this.approver,
      drftTaskId: drftTaskId ?? this.drftTaskId,
      projectName: projectName ?? this.projectName,
      milestoneName: milestoneName ?? this.milestoneName,
      projectRemarks: projectRemarks ?? this.projectRemarks,
      milestoneRemarks: milestoneRemarks ?? this.milestoneRemarks,
      taskRemarks: taskRemarks ?? this.taskRemarks,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rawStDt: rawStDt ?? this.rawStDt,
      rawEndDt: rawEndDt ?? this.rawEndDt,
      projectId: projectId ?? this.projectId,
      projectCode: projectCode ?? this.projectCode,
    );
  }

  // ============================================================
  // ✅ Status helpers (BIONOVA UI Standard)
  // ============================================================
  bool get isCompleted {
    final s = status.toUpperCase();
    final rawSts = (rawData?['taskSts'] ?? rawData?['status'] ?? '').toString().toUpperCase();
    return s == 'CLOSED' || s == 'COMPLETED' || s == 'DONE' || rawSts == 'CLOSED' || rawSts == 'COMPLETED' || rawSts == 'DONE' || rawSts == '4';
  }
  bool get isInProgress => status == 'In Progress' || status == 'WIP' || status == 'Reassigned' || status == 'Rework';
  bool get isUnderReview => status == 'Under Review';
  bool get isOpen => (status == 'Open' || status == 'Pending') && status != 'Reassigned' && status != 'Rework';
  bool get isReassigned {
    final s = status.toUpperCase();
    final sub = (rawData?['prcsYesActn'] ?? rawData?['prcs_yes_actn'] ?? rawData?['subStatus'] ?? rawData?['sub_status'] ?? '').toString().toUpperCase();
    if (s == 'REASSIGNED' || s == 'REASSIGN' || sub == 'REASSIGN' || sub == 'REASSIGNED') return true;
    final addlRem = (rawData?['addlRem'] ?? rawData?['remarks'] ?? '').toString();
    return addlRem.contains('[Reassigned') || addlRem.contains('reassign') || addlRem.contains('REASSIGN');
  }
  bool get isCriticalTag => tag == 'Critical';
  bool get isHighTag => tag == 'High';
  bool get isLowTag => tag == 'Low';

  bool get isDraft {
    final s = status.toUpperCase();
    final rawSts = (rawData?['taskSts'] ?? rawData?['task_sts'] ?? rawData?['status'] ?? rawData?['taskStatus'] ?? rawData?['sts'] ?? '').toString().toUpperCase().trim();
    int? stsId;
    if (rawData?['taskSts'] is Map) {
      stsId = int.tryParse((rawData!['taskSts']['statusId'] ?? rawData!['taskSts']['status_id'] ?? '').toString());
    } else {
      stsId = int.tryParse(rawSts);
    }
    return s == 'DRAFT' || rawSts == 'DRAFT' || stsId == 1 || rawData?['isDraft'] == true || rawData?['is_draft'] == true;
  }

  bool get isTodo {
    if (isCompleted || isDraft) return false;
    return !isUpcomingTask;
  }

  bool get isUpcomingTask {
    if (isCompleted || isDraft) return false;
    final s = status.toUpperCase();
    if (s == 'DRAFT') return false;

    final start = rawStDt ?? startDate ?? rawEndDt ?? endDate ?? date;
    if (start == null || start.isEmpty || start == 'No Date' || start == 'N/A') {
      return true;
    }

    try {
      DateTime? taskDate = parseDateTime(start);
      if (taskDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return !taskDate.isBefore(today);
      }
    } catch (_) {}
    return true;
  }

  String? get completionDate {
    final rawComp = rawData?['compDt'] ?? rawData?['completedDt'] ?? rawData?['actlEndDt'] ?? rawData?['updDt'];
    if (rawComp == null || rawComp.toString().trim().isEmpty) return null;
    final value = rawComp.toString().trim();
    if (value.length >= 10) {
      try {
        final parsed = DateTime.parse(value);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
      } catch (_) {
        return value.substring(0, 10);
      }
    }
    return value;
  }

  // 1. Progress Status (Badges - Exact same logic as website)
  String get progressStatusText {
    final s = status.toUpperCase();
    if (s == 'COMPLETED' || s == 'CLOSED') return 'CLOSED';
    if (s == 'UNDER REVIEW' || s == 'UNDER_REVIEW' || s == 'SUBMIT REVIEW' || s == 'SUBMIT_REVIEW') return 'UNDER REVIEW';
    if (s == 'REWORK') return 'REWORK';
    if (s == 'REASSIGNED' || s == 'REASSIGN') return 'REASSIGNED';
    if (s == 'HOLD') return 'HOLD';
    if (s == 'DRAFT') return 'DRAFT';
    if (s == 'OPEN' || s == 'PENDING') return 'OPEN';
    return 'IN PROGRESS';
  }

  Color get progressStatusColor {
    switch (progressStatusText) {
      case 'OPEN': return const Color(0xFF2563EB); // BLUE
      case 'IN PROGRESS': return const Color(0xFFD97706); // AMBER/GOLD #D97706
      case 'UNDER REVIEW': return const Color(0xFF7C3AED); // PURPLE #7C3AED
      case 'REWORK': return const Color(0xFFF97316); // ORANGE #F97316
      case 'REASSIGNED': return const Color(0xFF4F46E5); // INDIGO #4F46E5
      case 'HOLD': return const Color(0xFF7C3AED); // PURPLE
      case 'CLOSED':
      case 'COMPLETED': return const Color(0xFF16A34A); // GREEN
      case 'DRAFT': return const Color(0xFF9CA3AF); // GRAY
      default: return const Color(0xFF2563EB);
    }
  }

  Color get progressStatusBg {
    switch (progressStatusText) {
      case 'OPEN': return const Color(0xFFEFF6FF); 
      case 'IN PROGRESS': return const Color(0xFFFEF3C7); // Soft Gold tint #FEF3C7
      case 'UNDER REVIEW': return const Color(0xFFF3E8FF); // Soft Purple #F3E8FF
      case 'REWORK': return const Color(0xFFFFF7ED); // Soft Orange #FFF7ED
      case 'REASSIGNED': return const Color(0xFFEEF2FF); // Soft Indigo #EEF2FF
      case 'HOLD': return const Color(0xFFF5F3FF); 
      case 'CLOSED':
      case 'COMPLETED': return const Color(0xFFF0FDF4); 
      case 'DRAFT': return const Color(0xFFF3F4F6); 
      default: return const Color(0xFFEFF6FF);
    }
  }

  // 2. Process Status (Icons Only - Exact same icons & colors as website)
  IconData? get processIcon {
    final s = status.toUpperCase();
    final sub = (rawData?['prcsYesActn'] ?? rawData?['prcs_yes_actn'] ?? rawData?['subStatus'] ?? rawData?['sub_status'] ?? '').toString().toUpperCase();
    if (s == 'REWORK' || sub == 'REWORK') return Icons.sync_rounded;
    if (isReassigned) return Icons.undo_rounded;
    if (s == 'UNDER REVIEW' || s == 'UNDER_REVIEW' || sub.contains('PENDING')) return Icons.remove_red_eye_outlined;
    return null;
  }

  Color? get processIconColor {
    final s = status.toUpperCase();
    final sub = (rawData?['prcsYesActn'] ?? rawData?['prcs_yes_actn'] ?? rawData?['subStatus'] ?? rawData?['sub_status'] ?? '').toString().toUpperCase();
    if (s == 'REWORK' || sub == 'REWORK') return const Color(0xFFF97316); // ORANGE #F97316
    if (isReassigned) return const Color(0xFF4F46E5); // INDIGO #4F46E5
    if (s == 'UNDER REVIEW' || s == 'UNDER_REVIEW' || sub.contains('PENDING')) return const Color(0xFF8B5CF6); // PURPLE #8B5CF6
    return null;
  }

  String get processIconTooltip {
    final icon = processIcon;
    if (icon == Icons.remove_red_eye_outlined) return 'Under Review';
    if (icon == Icons.sync_rounded) return 'Rework';
    if (icon == Icons.undo_rounded) return 'Reassigned';
    return status;
  }

  // 3. Time Status (Icons Only)
  IconData get timeIcon => Icons.access_time_outlined;

  String get computedTimeStatus {
    // For closed/completed tasks — ALWAYS recalculate Lead/Lag/On Time.
    // Never trust cached timeStatus for closed tasks (it may be 'Overdue'
    // if status was sent as a numeric ID during JSON parsing).
    if (isCompleted) {
      if (rawEndDt == null || rawEndDt!.isEmpty) return 'On Time';
      try {
        final end = DateTime.parse(rawEndDt!);
        final target = DateTime(end.year, end.month, end.day);
        final rawComp = rawData?['compDt'] ?? rawData?['completedDt'] ??
            rawData?['actlEndDt'] ?? rawData?['actCmpDt'] ?? rawData?['updDt'];
        DateTime refDate;
        if (rawComp != null && rawComp.toString().isNotEmpty) {
          refDate = DateTime.parse(rawComp.toString());
        } else {
          final today = DateTime.now();
          refDate = DateTime(today.year, today.month, today.day);
        }
        final compStart = DateTime(refDate.year, refDate.month, refDate.day);
        if (compStart.isBefore(target)) return 'Lead';
        if (compStart.isAfter(target)) return 'Lag';
        return 'On Time';
      } catch (_) {
        return 'On Time';
      }
    }

    // For open tasks — ONLY return 'Due Today' or 'Overdue'. Never 'On Time', 'Lead', or 'Lag'!
    if (timeStatus != null && timeStatus!.isNotEmpty) {
      final ts = timeStatus!.trim().toLowerCase();
      if (ts == 'due today' || ts == 'duetoday') return 'Due Today';
      if (ts == 'overdue') return 'Overdue';
    }
    if (rawEndDt == null || rawEndDt!.isEmpty) return '';
    try {
      final end = DateTime.parse(rawEndDt!);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final target = DateTime(end.year, end.month, end.day);
      if (target.isBefore(todayStart)) return 'Overdue';
      if (target.isAtSameMomentAs(todayStart)) return 'Due Today';
      return '';
    } catch (_) {
      return '';
    }
  }

  Color get timeIconColor {
    switch (computedTimeStatus) {
      case 'Lead': return const Color(0xFF22C55E); // GREEN
      case 'On Time': return const Color(0xFF3B82F6); // BLUE
      case 'Due Today': return const Color(0xFFF59E0B); // AMBER
      case 'Overdue': return const Color(0xFFEF4444); // RED
      case 'Lag': return const Color(0xFFDC2626); // DARK RED
      default: return const Color(0xFF94A3B8); // GREY (For open future tasks)
    }
  }
}

// ============================================================
// ✅ GLOBAL TASKS - Static data for testing/offline use
// ============================================================
final List<TaskItem> globalTasks = [];