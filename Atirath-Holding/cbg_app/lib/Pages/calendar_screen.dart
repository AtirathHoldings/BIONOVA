import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import '../models/task_item.dart';
import 'task_details_screen.dart';
import '../utils/app_colors.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class CalendarTaskItem {
  final String id;
  final String title;
  final String projectCode;
  final String category;
  final String timeRange;
  final String priority;
  final Color priorityBgColor;
  final Color priorityTextColor;
  final Color themeColor;
  final String type;
  final Map<String, dynamic> rawItem;
  final String? startDate;
  final String? endDate;
  final String? dateBadge;
  final Color? dateBadgeBg;
  final Color? dateBadgeColor;
  final bool isClosed;
  final String? status;
  final String? leadLagText;
  final Color? leadLagBg;
  final Color? leadLagColor;

  CalendarTaskItem({
    required this.id,
    required this.title,
    required this.projectCode,
    required this.category,
    required this.timeRange,
    required this.priority,
    required this.priorityBgColor,
    required this.priorityTextColor,
    required this.themeColor,
    required this.type,
    required this.rawItem,
    this.startDate,
    this.endDate,
    this.dateBadge,
    this.dateBadgeBg,
    this.dateBadgeColor,
    this.isClosed = false,
    this.status,
    this.leadLagText,
    this.leadLagBg,
    this.leadLagColor,
  });
}

String _cleanCalendarLeadLagLabel(String statusStr) {
  final s = statusStr.trim();
  if (s.isEmpty) return 'ON TIME';
  final lower = s.toLowerCase();
  if (lower.contains('on time') || lower.contains('ontime') || lower == 'on-time') {
    return 'ON TIME';
  } else if (lower.contains('lag') || lower.contains('delayed') || lower.contains('delay')) {
    final match = RegExp(r'\d+').firstMatch(s);
    final daysNum = match?.group(0);
    if (daysNum != null && daysNum.isNotEmpty) {
      return 'LAG ($daysNum DAYS)';
    }
    return 'LAG';
  } else if (lower.contains('lead') || lower.contains('ahead')) {
    final match = RegExp(r'\d+').firstMatch(s);
    final daysNum = match?.group(0);
    if (daysNum != null && daysNum.isNotEmpty) {
      return 'LEAD ($daysNum DAYS)';
    }
    return 'LEAD';
  }
  return s.toUpperCase();
}

String calculateCalendarLeadLag(TaskItem task, [bool? isCompletedOverride]) {
  final bool isCompleted = isCompletedOverride ?? task.isCompleted;

  final String? apiStatus = task.rawData?['leadLagStatus']?.toString() ?? 
                            task.rawData?['lead_lag_status']?.toString() ?? 
                            task.rawData?['leadLagStatusStr']?.toString() ?? 
                            task.rawData?['scheduleStatus']?.toString();
  if (apiStatus != null && 
      apiStatus.isNotEmpty && 
      apiStatus.toLowerCase() != 'null' && 
      apiStatus.toLowerCase() != 'n/a') {
    return _cleanCalendarLeadLagLabel(apiStatus);
  }

  final String endStr = task.endDate ?? task.rawEndDt ?? task.date;
  if (endStr.isEmpty || endStr.toLowerCase() == 'no date' || endStr.toLowerCase() == 'n/a') {
    return 'ON TIME';
  }

  DateTime? endDt;
  try {
    endDt = DateTime.parse(endStr);
  } catch (_) {
    endDt = TaskItem.parseDateTime(endStr);
  }
  if (endDt == null) return 'ON TIME';

  final targetDate = DateTime(endDt.year, endDt.month, endDt.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (!isCompleted) {
    final diffDays = targetDate.difference(today).inDays;
    if (diffDays < 0) {
      return 'OVERDUE (${diffDays.abs()} DAYS)';
    } else if (diffDays == 0) {
      return 'DUE TODAY';
    } else {
      return 'LEAD ($diffDays DAYS)';
    }
  }

  String? actStr = task.rawData?['compDt']?.toString() ??
                   task.rawData?['completedDt']?.toString() ??
                   task.rawData?['actCmpDt']?.toString() ??
                   task.rawData?['act_cmp_dt']?.toString() ??
                   task.rawData?['actlEndDt']?.toString() ??
                   task.rawData?['updDt']?.toString();
  DateTime refDate = today;

  if (actStr != null && actStr.isNotEmpty) {
    DateTime? actDt;
    try { actDt = DateTime.parse(actStr); } catch (_) { actDt = TaskItem.parseDateTime(actStr); }
    if (actDt != null) {
      refDate = DateTime(actDt.year, actDt.month, actDt.day);
    }
  }

  final diffDays = targetDate.difference(refDate).inDays;
  if (diffDays > 0) {
    return 'LEAD ($diffDays DAYS)';
  } else if (diffDays < 0) {
    return 'LAG (${diffDays.abs()} DAYS)';
  } else {
    return 'ON TIME';
  }
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String _selectedTab = 'Month'; // 'Month', 'Week', 'Day'
  bool _isLoading = false;
  String? _error;
  List<TaskItem> _allTasks = [];
  int? _currentEmpId;
  // Set of holiday dates (yyyy-MM-dd) for fast lookup in calendar grid
  final Set<String> _holidayDateKeys = {};

  // Draggable Scrollable Controller to expand bottom panel on date clicks
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  final Map<String, List<CalendarTaskItem>> _eventsMap = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
    _fetchCalendarData();
  }

  Future<void> _handleRefresh() async {
    await ApiService.preloadAllData(forceRefresh: true);
    await _fetchCalendarData();
  }

  Future<void> _fetchCalendarData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String refDateStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-01';
      
      final results = await Future.wait([
        ApiService.getCalendarFeed(
          viewType: 'month',
          date: refDateStr,
        ),
        ApiService.getLiveTasks(),
        ApiService.getIndividualTasks(),
        ApiService.getCurrentEmployeeId(),
        ApiService.getCalendarHolidays(),
      ]);

      final List<dynamic> feed = results[0] as List<dynamic>;
      List<TaskItem> liveTasks = results[1] as List<TaskItem>;
      List<dynamic> rawIndividualTasks = results[2] as List<dynamic>;
      final currentEmpId = results[3] as int?;
      final holidaysList = results[4] as List<Map<String, dynamic>>;

      if (currentEmpId != null) {
        final empStr = currentEmpId.toString();

        liveTasks = liveTasks.where((t) {
          final raw = t.rawData ?? {};
          final doer = (raw['empId'] ?? raw['empid'] ?? raw['assignedTo'] ?? raw['executorId'])?.toString();
          final reviewer = (raw['reviewerId'] ?? raw['reviewer'] ?? t.reviewer)?.toString();
          final approver = (raw['approverId'] ?? raw['approver'] ?? t.approver)?.toString();
          final assigner = (raw['assignedBy'] ?? raw['assigned_by'] ?? raw['assignerId'] ?? raw['assigner_id'] ?? raw['crBy'] ?? raw['cr_by'])?.toString();
          final noteTxt = (raw['noteTxt'] ?? raw['note_txt'] ?? '').toString();
          final hasTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(empStr) ||
              (raw['teamMembers'] is List && (raw['teamMembers'] as List).any((tm) => tm['empId']?.toString() == empStr || tm['emp_id']?.toString() == empStr));
          return doer == empStr ||
              reviewer == empStr ||
              approver == empStr ||
              assigner == empStr ||
              t.isCurrentUserReviewer ||
              t.isCurrentUserApprover ||
              t.isCurrentUserExecutor ||
              t.isCurrentUserAssigner ||
              hasTeamMember;
        }).toList();

        rawIndividualTasks = rawIndividualTasks.where((t) {
          if (t is! Map) return false;
          final doer = (t['empId'] ?? t['empid'] ?? t['assignedTo'] ?? t['executorId'])?.toString();
          final reviewer = (t['reviewerId'] ?? t['reviewer'])?.toString();
          final approver = (t['approverId'] ?? t['approver'])?.toString();
          final assigner = (t['assignedBy'] ?? t['assigned_by'] ?? t['assignerId'] ?? t['assigner_id'] ?? t['crBy'] ?? t['cr_by'])?.toString();
          final noteTxt = (t['noteTxt'] ?? t['note_txt'] ?? '').toString();
          final hasTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(empStr) ||
              (t['teamMembers'] is List && (t['teamMembers'] as List).any((tm) => tm['empId']?.toString() == empStr || tm['emp_id']?.toString() == empStr));
          return doer == empStr || reviewer == empStr || approver == empStr || assigner == empStr || hasTeamMember;
        }).toList();
      }

      final individualTasks = rawIndividualTasks
          .whereType<Map<String, dynamic>>()
          .map((json) => TaskItem.fromIndividualTask(json, currentEmpId?.toString()))
          .toList();

      final allTasks = [...liveTasks, ...individualTasks].where((task) => !task.isDraft).toList();
      final Map<String, List<CalendarTaskItem>> newEventsMap = {};

      // 1. Process holidays from backend /api/calendar first
      for (final hMap in holidaysList) {
        final String dateKey = hMap['date']?.toString() ?? '';
        if (dateKey.isEmpty) continue;

        final String hTitle = hMap['title']?.toString() ?? 'Public Holiday';
        final String calTypeStr = (hMap['calType'] ?? 'MANDATORY').toString().toUpperCase();
        String badgeCode = 'Public Holiday';
        if (calTypeStr == 'COMPANY') {
          badgeCode = 'Company Holiday';
        } else if (calTypeStr == 'PLANT') {
          badgeCode = 'Plant Holiday';
        }

        final hEvent = CalendarTaskItem(
          id: (hMap['id'] ?? 'hol_$dateKey').toString(),
          title: hTitle,
          projectCode: badgeCode,
          category: 'HOLIDAY',
          timeRange: 'All Day',
          priority: 'Holiday',
          priorityBgColor: const Color(0xFFFFF1F2),
          priorityTextColor: const Color(0xFFE11D48),
          themeColor: const Color(0xFFE11D48),
          type: 'HOLIDAY',
          rawItem: hMap['raw'] ?? hMap,
        );

        if (!newEventsMap.containsKey(dateKey)) {
          newEventsMap[dateKey] = [];
        }
        if (!newEventsMap[dateKey]!.any((e) => e.type == 'HOLIDAY' && e.title == hTitle)) {
          newEventsMap[dateKey]!.add(hEvent);
        }
      }

      // 2. Process all tasks across their active lifecycle (Start Date to End Date / Due Date)
      for (final task in allTasks) {
        final Map<String, dynamic> raw = task.rawData ?? {};
        
        final String rawSt = (raw['stDt'] ?? raw['st_dt'] ?? raw['startDate'] ?? raw['start_date'] ?? task.rawStDt ?? task.startDate ?? '').toString().trim();
        final String rawEnd = (raw['endDt'] ?? raw['end_dt'] ?? raw['endDate'] ?? raw['end_date'] ?? raw['dueDt'] ?? raw['due_dt'] ?? raw['dueDate'] ?? raw['due_date'] ?? raw['targetDt'] ?? raw['target_dt'] ?? task.rawEndDt ?? task.endDate ?? task.date ?? '').toString().trim();

        DateTime? startDt = TaskItem.parseDateTime(rawSt);
        DateTime? endDt = TaskItem.parseDateTime(rawEnd);

        if (startDt == null && endDt == null) continue;
        startDt ??= endDt;
        endDt ??= startDt;

        if (startDt != null && endDt != null) {
          if (startDt.isAfter(endDt)) {
            endDt = startDt;
          }

          final DateTime startDay = DateTime(startDt.year, startDt.month, startDt.day);
          final DateTime endDay = DateTime(endDt.year, endDt.month, endDt.day);

          final String formattedStart = TaskItem.formatDateStr(rawSt.isNotEmpty ? rawSt : startDay.toIso8601String());
          final String formattedEnd = TaskItem.formatDateStr(rawEnd.isNotEmpty ? rawEnd : endDay.toIso8601String());

          final String taskId = task.id;
          final String prjCode = task.projectCode ?? (raw['prjCd'] ?? raw['projectCode'] ?? '').toString();
          final String mlstnCode = (raw['mlstnCd'] ?? raw['mlstn_cd'] ?? raw['milestoneCode'] ?? '').toString();

          String codeStr = '';
          if (prjCode.isNotEmpty && mlstnCode.isNotEmpty && prjCode != mlstnCode) {
            codeStr = '$prjCode  •  $mlstnCode';
          } else if (task.subtitle.isNotEmpty && !task.subtitle.startsWith('Role:')) {
            codeStr = task.subtitle;
          } else if (prjCode.isNotEmpty) {
            codeStr = prjCode;
          } else {
            codeStr = task.isIndividualTask ? 'IND-$taskId' : 'Task';
          }

          final bool isTaskClosed = task.isCompleted ||
              task.status.toLowerCase() == 'closed' ||
              task.status.toLowerCase() == 'completed' ||
              (raw['taskSts'] == 4 || raw['task_sts'] == 4 || raw['status'] == 4 || raw['taskSts'] == '4' || raw['task_sts'] == '4');

          String? leadLagText;
          Color? leadLagBg;
          Color? leadLagColor;

          if (isTaskClosed) {
            final ll = calculateCalendarLeadLag(task, true);
            leadLagText = ll;
            if (ll.contains('LEAD')) {
              leadLagBg = const Color(0xFFDCFCE7);
              leadLagColor = const Color(0xFF22C55E); // BIONOVA Lead #22C55E
            } else if (ll.contains('LAG')) {
              leadLagBg = const Color(0xFFFEE2E2);
              leadLagColor = const Color(0xFFDC2626); // BIONOVA Lag #DC2626
            } else {
              leadLagBg = const Color(0xFFDBEAFE);
              leadLagColor = const Color(0xFF3B82F6); // BIONOVA On Time #3B82F6
            }
          }

          // Compute priority & theme colors based on BIONOVA standards
          String priority = isTaskClosed ? 'Closed' : (task.priority.isNotEmpty ? task.priority : 'Normal');
          Color priorityBg = isTaskClosed ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
          Color priorityText = isTaskClosed ? const Color(0xFF16A34A) : const Color(0xFF3B82F6);
          Color themeColor = isTaskClosed ? const Color(0xFF16A34A) : task.iconColor;

          if (!isTaskClosed) {
            final upperPrty = priority.toUpperCase();
            if (upperPrty.contains('CRITICAL')) {
              priorityBg = const Color(0xFFFEE2E2);
              priorityText = const Color(0xFFB91C1C); // BIONOVA Critical #B91C1C
              themeColor = const Color(0xFFB91C1C);
            } else if (upperPrty.contains('HIGH')) {
              priorityBg = const Color(0xFFFEF2F2);
              priorityText = const Color(0xFFEF4444); // BIONOVA High #EF4444
              themeColor = const Color(0xFFEF4444);
            } else if (upperPrty.contains('MEDIUM') || upperPrty.contains('WIP')) {
              priorityBg = const Color(0xFFFEF3C7);
              priorityText = const Color(0xFFF59E0B); // BIONOVA Medium #F59E0B
              themeColor = const Color(0xFFF59E0B);
            } else if (upperPrty.contains('NORMAL')) {
              priorityBg = const Color(0xFFDBEAFE);
              priorityText = const Color(0xFF3B82F6); // BIONOVA Normal #3B82F6
              themeColor = const Color(0xFF3B82F6);
            } else {
              priorityBg = const Color(0xFFDCFCE7);
              priorityText = const Color(0xFF22C55E); // BIONOVA Low #22C55E
              themeColor = const Color(0xFF22C55E);
            }
          }

          final List<Map<String, dynamic>> targetDates = [];
          final bool isSingleDay = (startDay.year == endDay.year && startDay.month == endDay.month && startDay.day == endDay.day);

          if (isSingleDay) {
            targetDates.add({
              'date': startDay,
              'badge': 'Due Date',
              'badgeBg': const Color(0xFFEFF6FF),
              'badgeColor': const Color(0xFF2563EB),
            });
          } else {
            // 1. Start Date only
            targetDates.add({
              'date': startDay,
              'badge': 'Start Date',
              'badgeBg': const Color(0xFFECFDF5),
              'badgeColor': const Color(0xFF10B981),
            });

            // 2. Due Date only
            targetDates.add({
              'date': endDay,
              'badge': 'Due Date',
              'badgeBg': const Color(0xFFFEF2F2),
              'badgeColor': const Color(0xFFEF4444),
            });
          }

          for (final tDateInfo in targetDates) {
            final DateTime d = tDateInfo['date'] as DateTime;
            final dateKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            final String dateBadge = tDateInfo['badge'] as String;
            final Color badgeBg = tDateInfo['badgeBg'] as Color;
            final Color badgeColor = tDateInfo['badgeColor'] as Color;

            final eventItem = CalendarTaskItem(
              id: taskId,
              title: task.title,
              projectCode: codeStr,
              category: 'TASK',
              timeRange: 'All Day',
              priority: priority,
              priorityBgColor: priorityBg,
              priorityTextColor: priorityText,
              themeColor: themeColor,
              type: 'TASK',
              rawItem: raw.isNotEmpty ? raw : {'taskId': task.id, 'title': task.title},
              startDate: formattedStart,
              endDate: formattedEnd,
              dateBadge: dateBadge,
              dateBadgeBg: badgeBg,
              dateBadgeColor: badgeColor,
              isClosed: isTaskClosed,
              status: task.status,
              leadLagText: leadLagText,
              leadLagBg: leadLagBg,
              leadLagColor: leadLagColor,
            );

            if (!newEventsMap.containsKey(dateKey)) {
              newEventsMap[dateKey] = [];
            }
            if (!newEventsMap[dateKey]!.any((e) => e.type == 'TASK' && e.id == taskId)) {
              newEventsMap[dateKey]!.add(eventItem);
            }
          }
        }
      }

      // 3. Process calendar feed items for any remaining feed items not in allTasks
      for (var item in feed) {
        final String dateRaw = item['date']?.toString() ?? '';
        if (dateRaw.isEmpty) continue;

        String dateKey = dateRaw;
        if (dateRaw.contains('T')) {
          dateKey = dateRaw.split('T')[0];
        }

        final String type = (item['type']?.toString() ?? 'TASK').toUpperCase();
        // ✅ Allow TASK and HOLIDAY types (skip others like MILESTONE, etc)
        if (type != 'TASK' && type != 'HOLIDAY') continue;

        final String eventId = (item['taskId'] ?? item['task_id'] ?? item['empTaskId'] ?? item['emp_task_id'] ?? item['tId'] ?? item['t_id'] ?? item['id'] ?? '').toString();

        if (newEventsMap.containsKey(dateKey) &&
            newEventsMap[dateKey]!.any((e) => (type == 'HOLIDAY' && e.type == 'HOLIDAY') || (type == 'TASK' && e.id == eventId))) {
          continue;
        }

        final String title = (item['title'] ?? item['holidayNm'] ?? item['holiday_nm'] ?? item['calOcc'] ?? item['name'] ?? '').toString();
        if (type == 'HOLIDAY') {
          if (newEventsMap.containsKey(dateKey) &&
              newEventsMap[dateKey]!.any((e) => e.type == 'HOLIDAY')) {
            continue;
          }
        }

        final String rawCode = item['code']?.toString() ?? '';
        final String prjCode = (item['prjCd'] ?? item['projectCode'] ?? item['project_code'] ?? item['prjId'] ?? item['projectId'] ?? item['project_id'] ?? '').toString();
        final String mlstnCode = (item['mlstnCd'] ?? item['mlstn_cd'] ?? item['milestoneCode'] ?? item['milestone_code'] ?? item['mlstnId'] ?? item['milestoneId'] ?? item['milestone_id'] ?? item['mId'] ?? item['mid'] ?? '').toString();
        
        String codeStr = '';
        if (type == 'HOLIDAY') {
          codeStr = 'Public Holiday';
        } else if (prjCode.isNotEmpty && mlstnCode.isNotEmpty && prjCode != mlstnCode) {
          codeStr = '$prjCode  •  $mlstnCode';
        } else if (prjCode.isNotEmpty) {
          codeStr = prjCode;
        } else if (mlstnCode.isNotEmpty) {
          codeStr = mlstnCode;
        } else if (rawCode.isNotEmpty) {
          codeStr = rawCode;
        } else {
          codeStr = 'N/A';
        }

        final String time = item['time']?.toString() ?? 'All Day';
        final String status = item['status']?.toString() ?? 'OPEN';

        String priority = 'Medium';
        Color priorityBg = const Color(0xFFFEF3C7);
        Color priorityText = const Color(0xFFF59E0B);
        Color themeColor = const Color(0xFFF59E0B);

        if (type == 'HOLIDAY') {
          priority = 'Holiday';
          priorityBg = const Color(0xFFFFF1F2);
          priorityText = const Color(0xFFE11D48);
          themeColor = const Color(0xFFE11D48);
        } else {
          if (status == 'HIGH' || status == 'COMPLETED') {
            priority = 'High';
            priorityBg = AppColors.overdueBg;
            priorityText = AppColors.overdue;
            themeColor = AppColors.overdue;
          } else if (status == 'WIP' || status == 'UNDER_REVIEW' || status == 'MEDIUM') {
            priority = 'Medium';
            priorityBg = AppColors.inProgressBg;
            priorityText = AppColors.inProgress;
            themeColor = AppColors.inProgress;
          } else {
            priority = 'Low';
            priorityBg = AppColors.closedBg;
            priorityText = AppColors.closed;
            themeColor = AppColors.closed;
          }
        }

        final eventItem = CalendarTaskItem(
          id: eventId,
          title: title.isNotEmpty ? title : 'Holiday',
          projectCode: codeStr,
          category: type,
          timeRange: time.isNotEmpty ? time : 'All Day',
          priority: priority,
          priorityBgColor: priorityBg,
          priorityTextColor: priorityText,
          themeColor: themeColor,
          type: type,
          rawItem: item,
          startDate: type == 'HOLIDAY' ? null : item['startDate']?.toString(),
          endDate: type == 'HOLIDAY' ? null : (item['endDate']?.toString() ?? item['date']?.toString()),
          dateBadge: type == 'HOLIDAY' ? null : 'Due Today',
          dateBadgeBg: type == 'HOLIDAY' ? null : const Color(0xFFEFF6FF),
          dateBadgeColor: type == 'HOLIDAY' ? null : const Color(0xFF2563EB),
        );

        if (!newEventsMap.containsKey(dateKey)) {
          newEventsMap[dateKey] = [];
        }
        newEventsMap[dateKey]!.add(eventItem);
      }

      if (mounted) {
        setState(() {
          _eventsMap.clear();
          _eventsMap.addAll(newEventsMap);
          // Build holiday date keys set for calendar grid highlight
          _holidayDateKeys.clear();
          for (final entry in newEventsMap.entries) {
            if (entry.value.any((e) => e.type == 'HOLIDAY')) {
              _holidayDateKeys.add(entry.key);
            }
          }
          _allTasks = allTasks;
          _currentEmpId = currentEmpId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleNotification() {
    Navigator.pushNamed(context, '/notifications');
  }

  TaskItem? _findMatchedTask(CalendarTaskItem calendarItem) {
    if (calendarItem.type != 'TASK' && calendarItem.category != 'TASK') {
      return null;
    }

    final Map<String, dynamic> raw = calendarItem.rawItem;

    // Collect all candidate IDs from calendarItem and its raw map
    final Set<String> candidateIds = {};
    if (calendarItem.id.isNotEmpty) candidateIds.add(calendarItem.id.trim());
    for (final key in ['taskId', 'task_id', 'empTaskId', 'emp_task_id', 'tId', 't_id', 'drftTaskId', 'drft_task_id', 'id']) {
      final val = raw[key]?.toString().trim();
      if (val != null && val.isNotEmpty) {
        candidateIds.add(val);
        final digitsOnly = val.replaceAll(RegExp(r'[^\d]'), '');
        if (digitsOnly.isNotEmpty && digitsOnly != '0') {
          candidateIds.add(digitsOnly);
        }
      }
    }

    // 1. Check ID overlap in _allTasks
    for (final t in _allTasks) {
      final Set<String> taskIds = {};
      if (t.id.isNotEmpty) {
        taskIds.add(t.id.trim());
        final digitsOnly = t.id.replaceAll(RegExp(r'[^\d]'), '');
        if (digitsOnly.isNotEmpty && digitsOnly != '0') taskIds.add(digitsOnly);
      }
      if (t.drftTaskId != null && t.drftTaskId!.isNotEmpty) {
        taskIds.add(t.drftTaskId!.trim());
      }
      if (t.rawData != null) {
        for (final key in ['taskId', 'task_id', 'empTaskId', 'emp_task_id', 'tId', 't_id', 'id']) {
          final val = t.rawData![key]?.toString().trim();
          if (val != null && val.isNotEmpty) {
            taskIds.add(val);
            final digitsOnly = val.replaceAll(RegExp(r'[^\d]'), '');
            if (digitsOnly.isNotEmpty && digitsOnly != '0') taskIds.add(digitsOnly);
          }
        }
      }

      if (candidateIds.any((id) => taskIds.contains(id))) {
        return t;
      }
    }

    // 2. Check title matching in _allTasks
    final String cleanTitle = calendarItem.title.trim().toLowerCase();
    if (cleanTitle.isNotEmpty) {
      for (final t in _allTasks) {
        final String taskTitle = t.title.trim().toLowerCase();
        if (taskTitle == cleanTitle || (taskTitle.isNotEmpty && (taskTitle.contains(cleanTitle) || cleanTitle.contains(taskTitle)))) {
          return t;
        }
      }
    }

    // 3. Fallback: Construct TaskItem directly from rawItem if not present in _allTasks
    final bool isIndiv = (raw['isIndividualTask'] == true ||
        raw['isIndividual'] == true ||
        raw['empTaskId'] != null ||
        raw['emp_task_id'] != null ||
        calendarItem.category == 'INDIVIDUAL' ||
        raw['type']?.toString().toUpperCase() == 'INDIVIDUAL');

    if (isIndiv) {
      return TaskItem.fromIndividualTask(raw, _currentEmpId?.toString());
    } else {
      return TaskItem.fromLiveTask(raw, _currentEmpId?.toString());
    }
  }

  void _navigateToTaskDetails(CalendarTaskItem calendarItem) async {
    if (calendarItem.type != 'TASK' && calendarItem.category != 'TASK') {
      return;
    }

    final TaskItem? matchedTask = _findMatchedTask(calendarItem);

    if (matchedTask != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailsScreen(
            task: matchedTask,
            isIndividualTask: matchedTask.isIndividualTask,
          ),
        ),
      );
      _fetchCalendarData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task details not found for "${calendarItem.title}"'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _previousMonth() {
    setState(() {
      if (_selectedTab == 'Week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else if (_selectedTab == 'Day') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
        final int targetDay = _selectedDate.day.clamp(1, DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day);
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, targetDay);
      }
    });
    _fetchCalendarData();
  }

  void _nextMonth() {
    setState(() {
      if (_selectedTab == 'Week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else if (_selectedTab == 'Day') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
        final int targetDay = _selectedDate.day.clamp(1, DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day);
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, targetDay);
      }
    });
    _fetchCalendarData();
  }

  DateTime? _parseValidDate(String text) {
    final clean = text.trim();
    if (clean.length != 10) return null;
    final parts = clean.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    if (year < 2000 || year > 2030) return null;

    try {
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectYearMonth(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dateController = TextEditingController(
          text: DateFormat('dd/MM/yyyy').format(_selectedDate),
        );
        String? dateError;
        DateTime? tempDate = _selectedDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void parseText(String text) {
              if (text.isEmpty) {
                setModalState(() {
                  tempDate = null;
                  dateError = null;
                });
                return;
              }
              if (text.length == 10) {
                final picked = _parseValidDate(text);
                if (picked == null) {
                  setModalState(() {
                    dateError = 'Invalid Date';
                    tempDate = null;
                  });
                  return;
                }
                final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                if (picked.isBefore(today)) {
                  setModalState(() {
                    dateError = 'Date cannot be in the past';
                    tempDate = null;
                  });
                  return;
                }
                setModalState(() {
                  dateError = null;
                  tempDate = picked;
                });
              } else {
                setModalState(() {
                  dateError = 'Invalid Date';
                  tempDate = null;
                });
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Go to Date',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter Date (DD/MM/YYYY)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: dateController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      DateInputFormatter(),
                    ],
                    onChanged: parseText,
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'DD/MM/YYYY',
                      errorText: dateError,
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2563EB)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: Color(0xFF2563EB)),
                        tooltip: 'Pick Date Visual',
                        onPressed: () async {
                          final DateTime today = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          );
                          final DateTime initialTo = (tempDate != null && !tempDate!.isBefore(today))
                              ? tempDate!
                              : (_selectedDate.isBefore(today) ? today : _selectedDate);
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initialTo,
                            firstDate: today,
                            lastDate: DateTime(2030),
                            initialEntryMode: DatePickerEntryMode.calendarOnly,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF2563EB),
                                    onPrimary: Colors.white,
                                    onSurface: Color(0xFF1E293B),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            final formatted = DateFormat('dd/MM/yyyy').format(picked);
                            dateController.text = formatted;
                            setModalState(() {
                              dateError = null;
                              tempDate = picked;
                            });
                          }
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: tempDate != null ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = dateController.text.trim();
                        final picked = _parseValidDate(text);
                        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                        if (picked != null && !picked.isBefore(today)) {
                          setState(() {
                            _selectedDate = picked;
                            _currentMonth = DateTime(picked.year, picked.month, 1);
                          });
                          _fetchCalendarData();
                          Navigator.pop(context);
                        } else if (picked != null && picked.isBefore(today)) {
                          setModalState(() {
                            dateError = 'Date cannot be in the past';
                          });
                        } else {
                          setModalState(() {
                            dateError = 'Please enter a valid date in DD/MM/YYYY format';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Apply Date',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String get _navigationHeaderTitle {
    if (_selectedTab == 'Week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      if (startOfWeek.month == endOfWeek.month) {
        return '${DateFormat('d').format(startOfWeek)} - ${DateFormat('d MMMM yyyy').format(endOfWeek)}';
      } else {
        return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      }
    } else if (_selectedTab == 'Day') {
      return DateFormat('d MMMM yyyy').format(_selectedDate);
    }
    return DateFormat('MMMM yyyy').format(_currentMonth);
  }

  // Returns 42 days for the calendar grid
  List<DateTime> _generateGridDates(DateTime monthDate) {
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final padDays = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final gridStart = firstDay.subtract(Duration(days: padDays));
    return List.generate(42, (index) => gridStart.add(Duration(days: index)));
  }

  // Get dots for a specific day
  List<Color> _getDayDotColors(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final tasks = _eventsMap[key];
    if (tasks == null || tasks.isEmpty) return [];
    return tasks.map((t) => t.themeColor).toSet().toList();
  }

  // Animates sheet to expanded view when clicking on a date
  void _expandBottomSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Helper to format Date
  String _formatSelectedDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  Widget _buildTaskItem(CalendarTaskItem item) {
    final bool isHoliday = item.type == 'HOLIDAY';
    final bool isTask = !isHoliday && (item.type == 'TASK' || item.category == 'TASK');
    final TaskItem? matchedTask = isTask ? _findMatchedTask(item) : null;

    String subtitleText = item.projectCode;
    if (isTask) {
      if (matchedTask != null) {
        if (matchedTask.subtitle.isNotEmpty && !matchedTask.subtitle.startsWith('Role:')) {
          if (!matchedTask.subtitle.contains('•') && item.projectCode.contains('•')) {
            subtitleText = item.projectCode;
          } else {
            subtitleText = matchedTask.subtitle;
          }
        } else if (matchedTask.isIndividualTask) {
          final idStr = matchedTask.id.isNotEmpty ? matchedTask.id : item.id;
          if (matchedTask.projectCode != null && matchedTask.projectCode!.isNotEmpty) {
            subtitleText = '${matchedTask.projectCode}  •  IND-$idStr';
          } else if (idStr.isNotEmpty && idStr != '0') {
            subtitleText = 'IND-$idStr';
          } else {
            subtitleText = item.projectCode.isNotEmpty && item.projectCode != 'N/A' ? item.projectCode : 'Individual Task';
          }
        }
      }
      if (subtitleText.isEmpty || subtitleText == 'N/A') {
        subtitleText = item.projectCode.isNotEmpty && item.projectCode != 'N/A'
            ? item.projectCode
            : (item.id.isNotEmpty ? 'ID: ${item.id}' : item.category);
      }
    } else if (isHoliday) {
      if (subtitleText.isEmpty || subtitleText == 'N/A') {
        subtitleText = 'Public Holiday';
      }
    }

    final bool showTimeRange = !isHoliday && item.timeRange.toLowerCase().trim() != 'all day';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: isTask ? () => _navigateToTaskDetails(item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: item.themeColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isHoliday) ...[
                              const Icon(Icons.celebration_rounded, size: 14, color: Color(0xFFE11D48)),
                              const SizedBox(width: 6),
                            ] else ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: item.themeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                item.title,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitleText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        if (!isHoliday && item.startDate != null && item.startDate!.isNotEmpty && item.endDate != null && item.endDate!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.date_range_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Start: ${item.startDate}   •   Due: ${item.endDate}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else if (!isHoliday && item.endDate != null && item.endDate!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Due Date: ${item.endDate}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (showTimeRange) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                item.timeRange,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.isClosed) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                          ),
                          child: Text(
                            'Closed',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF16A34A),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isHoliday && item.dateBadge != null && item.dateBadge!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.dateBadgeBg ?? const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (item.dateBadgeColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              item.dateBadge!,
                              style: TextStyle(
                                color: item.dateBadgeColor ?? const Color(0xFF2563EB),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: item.priorityBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.priority,
                            style: TextStyle(
                              color: item.priorityTextColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isHoliday && item.dateBadge != null && item.dateBadge!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.dateBadgeBg ?? const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (item.dateBadgeColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              item.dateBadge!,
                              style: TextStyle(
                                color: item.dateBadgeColor ?? const Color(0xFF2563EB),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridDates = _generateGridDates(_currentMonth);
    final selectedKey = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    // Active events for selected date
    final List<CalendarTaskItem> activeTasks = _eventsMap[selectedKey] ?? [];
    final List<CalendarTaskItem> dayTasks = activeTasks.where((e) => e.type == 'TASK' || e.category == 'TASK').toList();
    final List<CalendarTaskItem> dayHolidays = activeTasks.where((e) => e.type == 'HOLIDAY' || e.category == 'HOLIDAY').toList();

    String summaryCountText;
    if (dayTasks.isNotEmpty && dayHolidays.isNotEmpty) {
      summaryCountText = '${dayTasks.length} ${dayTasks.length == 1 ? 'Task' : 'Tasks'} • ${dayHolidays.length} ${dayHolidays.length == 1 ? 'Holiday' : 'Holidays'}';
    } else if (dayTasks.isNotEmpty) {
      summaryCountText = '${dayTasks.length} ${dayTasks.length == 1 ? 'Task' : 'Tasks'}';
    } else if (dayHolidays.isNotEmpty) {
      summaryCountText = '${dayHolidays.length} ${dayHolidays.length == 1 ? 'Holiday' : 'Holidays'}';
    } else {
      summaryCountText = '0 Tasks';
    }

    final List<CalendarTaskItem> sortedDayEvents = [...activeTasks];
    sortedDayEvents.sort((a, b) {
      if (a.type == 'HOLIDAY' && b.type != 'HOLIDAY') return -1;
      if (a.type != 'HOLIDAY' && b.type == 'HOLIDAY') return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Background Content (Scrollable Calendar View with Pull-to-Refresh)
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120), // Bottom padding so calendar grid isn't blocked when sheet is collapsed
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calendar Subtitle Header
                      Text(
                        'View and manage your schedule, tasks and project deadlines.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Month Navigation Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _previousMonth,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF475569)),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _selectYearMonth(context),
                                child: Row(
                                  children: [
                                    Text(
                                      _navigationHeaderTitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0F172A)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  final now = DateTime.now();
                                  setState(() {
                                    _selectedDate = now;
                                    _currentMonth = DateTime(now.year, now.month, 1);
                                  });
                                  _fetchCalendarData();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _nextMonth,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const LinearProgressIndicator(minHeight: 2, color: Color(0xFF2563EB), backgroundColor: Color(0xFFF1F5F9))
                      else
                        const SizedBox(height: 2),
                      const SizedBox(height: 8),

                      // View Selector Tabs (Month, Week, Day)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: ['Month', 'Week', 'Day'].map((tab) {
                            final isSelected = _selectedTab == tab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = tab),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tab,
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Views
                      if (_selectedTab == 'Month') ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: 49,
                          itemBuilder: (context, index) {
                            if (index < 7) {
                              final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                              return Center(
                                child: Text(
                                  weekdays[index],
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }

                            final date = gridDates[index - 7];
                            final isCurrentMonth = date.month == _currentMonth.month;
                            final isSelected = date.day == _selectedDate.day &&
                                date.month == _selectedDate.month &&
                                date.year == _selectedDate.year;
                            
                            final now = DateTime.now();
                            final isToday = date.day == now.day &&
                                date.month == now.month &&
                                date.year == now.year;

                            final dotColors = _getDayDotColors(date);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                  if (date.month != _currentMonth.month || date.year != _currentMonth.year) {
                                    _currentMonth = DateTime(date.year, date.month, 1);
                                    _fetchCalendarData();
                                  }
                                });
                                _expandBottomSheet();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isSelected && isToday)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEA580C),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${date.day}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      )
                                    else if (isSelected && !isToday)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${date.day}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      )
                                    else if (!isSelected && isToday)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFEA580C),
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${date.day}',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFEA580C),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${date.day}',
                                          style: GoogleFonts.inter(
                                            color: isCurrentMonth ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                            fontWeight: isCurrentMonth ? FontWeight.w600 : FontWeight.normal,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 3),
                                    if (dotColors.isNotEmpty)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: dotColors.take(3).map((color) {
                                          return Container(
                                            width: 4.5,
                                            height: 4.5,
                                            margin: const EdgeInsets.symmetric(horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    else
                                      const SizedBox(height: 4.5),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ] else if (_selectedTab == 'Week') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Timeline',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(7, (i) {
                                  final dayDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)).add(Duration(days: i));
                                  final isSelected = dayDate.day == _selectedDate.day && dayDate.month == _selectedDate.month && dayDate.year == _selectedDate.year;
                                  final now = DateTime.now();
                                  final isToday = dayDate.day == now.day && dayDate.month == now.month && dayDate.year == now.year;
                                  final dotColors = _getDayDotColors(dayDate);
                                  return Column(
                                    children: [
                                      Text(
                                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                        style: TextStyle(color: isToday ? const Color(0xFFD97706) : Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedDate = dayDate;
                                            if (dayDate.month != _currentMonth.month || dayDate.year != _currentMonth.year) {
                                              _currentMonth = DateTime(dayDate.year, dayDate.month, 1);
                                              _fetchCalendarData();
                                            }
                                          });
                                          _expandBottomSheet();
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: (isSelected && isToday)
                                                    ? const Color(0xFFEA580C)
                                                    : ((isSelected && !isToday)
                                                        ? const Color(0xFF2563EB)
                                                        : (isToday ? const Color(0xFFFFF7ED) : Colors.transparent)),
                                                shape: BoxShape.circle,
                                                border: (!isSelected && isToday)
                                                    ? Border.all(color: const Color(0xFFEA580C), width: 1.8)
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${dayDate.day}',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : (isToday ? const Color(0xFFEA580C) : const Color(0xFF1E293B)),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            if (dotColors.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: dotColors.map((color) {
                                                  return Container(
                                                    width: 4.5,
                                                    height: 4.5,
                                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ] else ...[
                                              const SizedBox(height: 7.5),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('d MMMM yyyy').format(_selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFDBEAFE)),
                                ),
                                child: Text(
                                  summaryCountText,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sortedDayEvents.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Text(
                              'No tasks or events scheduled for this day.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedDayEvents.length,
                            itemBuilder: (context, index) {
                              return _buildTaskItem(sortedDayEvents[index]);
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
            
            // 2. Foreground Content (Draggable Scrollable Bottom Panel for Events & Tasks)
            if (_selectedTab != 'Day')
              DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.15,
              minChildSize: 0.08,
              maxChildSize: 0.75,
              snap: true,
              snapSizes: const [0.08, 0.45, 0.75],
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: 3 + (sortedDayEvents.isEmpty ? 1 : sortedDayEvents.length),
                    itemBuilder: (BuildContext context, int index) {
                      // Item 0: Drag Handle Indicator
                      if (index == 0) {
                        return Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(top: 10, bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }

                      // Item 1: Date Header Row
                      if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatSelectedDate(_selectedDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  if (dayTasks.isNotEmpty && MainScreen.navigatorKey.currentState != null) {
                                    MainScreen.navigatorKey.currentState!.changeTab(2); // Go to tasks tab
                                  }
                                },
                                child: Text(
                                  summaryCountText,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Render Tasks or Empty State
                      if (sortedDayEvents.isEmpty) {
                        if (index == 2) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Text(
                              'No tasks or events scheduled for this day.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          );
                        }
                      } else {
                        if (index >= 2 && index < 2 + sortedDayEvents.length) {
                          final item = sortedDayEvents[index - 2];
                          return _buildTaskItem(item);
                        }
                      }

                      // Last Item: View all tasks link
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () {
                              if (MainScreen.navigatorKey.currentState != null) {
                                MainScreen.navigatorKey.currentState!.changeTab(2); // Go to tasks tab
                              }
                            },
                            icon: Text(
                              'View all tasks',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            label: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}