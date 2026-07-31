import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';
import '../models/project_model.dart';
import '../models/task_item.dart';
import '../services/api_service.dart';

// --- DATA MODELS ---
class MilestoneModel {
  final String id;
  final String title;
  final String desc;
  final String startDate;
  final String targetDate;
  final int progress;
  final int assigned;
  final int open;
  final String status;
  final Color color;

  MilestoneModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.startDate,
    required this.targetDate,
    required this.progress,
    required this.assigned,
    required this.open,
    required this.status,
    required this.color,
  });
}

class TaskModel {
  final String code;
  final String name;
  final String assignedTo;
  final String priority;
  final String dueDate;
  final String status;
  final double progress;
  final Color priorityColor;
  final Color statusColor;
  final TaskItem taskItem;
  final String milestoneTitle;

  TaskModel({
    required this.code,
    required this.name,
    required this.assignedTo,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.progress,
    required this.priorityColor,
    required this.statusColor,
    required this.taskItem,
    required this.milestoneTitle,
  });
}

class GanttItemModel {
  final String id;
  final String milestoneName;
  final String taskName;
  final String progress;
  final int startDay;
  final int durationDays;
  final Color color;

  GanttItemModel({
    required this.id,
    required this.milestoneName,
    required this.taskName,
    required this.progress,
    required this.startDay,
    required this.durationDays,
    required this.color,
  });
}

// --- MAIN SCREEN WIDGET ---
class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _currentIndex = 1;

  // Scroll controller
  final ScrollController _horizontalScrollController = ScrollController();

  // Gantt Chart Matrix Constraints
  static const double rowHeight = 50.0;
  static const double barHeight = 28.0;
  static const double ganttHeaderHeight = 50.0;
  double _baseDayWidth = 28.0;
  double _scaleFactor = 1.0;
  double _zoomPercent = 70.0;

  String _selectedMilestone = "All Milestones";
  List<String> _milestoneNames = ["All Milestones"];
  String? _selectedMilestoneTitle;

  List<MilestoneModel> _milestones = [];
  List<TaskModel> _tasks = [];
  List<GanttItemModel> _ganttData = [];
  DateTime? _ganttProjectStart;
  List<Map<String, dynamic>> _projectDocuments = [];
  bool _isLoadingDocuments = false;

  ProjectModel? _project;
  bool _isProjectLoaded = false;
  bool _isLoading = false;
  String? _error;
  String _projectLocation = 'Loading Location...';
  int _unreadNotificationCount = 0;

  int? _currentEmpId;
  bool _filterByEmp = false;
  String _leadLagStatus = 'Lag';
  String _userDepartment = 'Loading...';

  Future<void> _fetchNotificationCount() async {
    try {
      final unreadNotifications = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<void> _fetchProjectData() async {
    if (_project == null) {
      setState(() { _isLoading = false; });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _fetchNotificationCount();

    try {
      // Fetch latest project details from backend
      try {
        final latestProjects = await ApiService.getLiveProjects();
        final updatedProject = latestProjects.firstWhere(
          (p) => p.prjId == _project!.prjId,
          orElse: () => _project!,
        );
        _project = updatedProject;
      } catch (pe) {
        debugPrint('Error updating project details from backend: $pe');
      }

      // Fetch user profile department from backend
      String userDept = 'N/A';
      try {
        final profile = await ApiService.getProfile();
        userDept = profile['deptNm']?.toString() ?? profile['department']?.toString() ?? profile['deptId']?.toString() ?? 'N/A';
      } catch (pe) {
        debugPrint('Error fetching user profile department: $pe');
      }

      // Fetch plant location
      if (_project?.location != null && _project!.location!.isNotEmpty && _project!.location != 'Loading Location...') {
        _projectLocation = _project!.location!;
      } else if (_project?.pltId != null && _project!.pltId! > 0) {
        try {
          final plants = await ApiService.getPlants();
          final match = plants.firstWhere(
            (p) => (p['pltId'] ?? p['plt_id']) == _project!.pltId,
            orElse: () => null,
          );
          if (match != null) {
            final String addr = match['addr'] ?? '';
            final String dist = match['dist'] ?? '';
            final String pltNm = match['pltNm'] ?? match['plt_nm'] ?? '';
            
            List<String> parts = [];
            if (pltNm.isNotEmpty) parts.add(pltNm);
            if (dist.isNotEmpty) parts.add(dist);
            if (addr.isNotEmpty && parts.length < 2) parts.add(addr);
            
            _projectLocation = parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
          } else {
            _projectLocation = 'Location Not Found';
          }
        } catch (pe) {
          debugPrint('Error fetching plant: $pe');
          _projectLocation = 'Unknown Location';
        }
      } else {
        _projectLocation = 'No Location Assigned';
      }

      final currentEmpId = await ApiService.getCurrentEmployeeId();
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('userRole') ?? '';
      final filterByEmp = currentEmpId != null &&
          role.isNotEmpty &&
          role.toLowerCase() != 'admin' &&
          role.toLowerCase() != 'manager';

      if (mounted) {
        setState(() {
          _currentEmpId = currentEmpId;
          _filterByEmp = filterByEmp;
        });
      }

      List<dynamic> rawMilestones = [];
      List<List<dynamic>> allRawTasks = [];
      List<dynamic> rawGantt = [];

      // Always fetch all project data regardless of user role
      List<dynamic> fetchedMilestones = [];
      try {
        fetchedMilestones = await ApiService.getMilestones(_project!.prjId);
      } catch (me) {
        debugPrint('Error fetching project milestones: $me');
      }

      String leadLag = _project?.leadLagStatusStr ?? 'Lag';
      try {
        leadLag = await ApiService.getProjectLeadLagStatus(_project!.prjId);
      } catch (e) {
        debugPrint('Error fetching project lead lag status: $e');
      }

      List<dynamic> fetchedGantt = [];
      try {
        fetchedGantt = await ApiService.getGanttData(_project!.prjId);
      } catch (ge) {
        debugPrint('Error fetching gantt data: $ge');
      }

      rawMilestones = fetchedMilestones;
      rawGantt = fetchedGantt;

      final List<Future<List<dynamic>>> taskFutures = rawMilestones.map((m) async {
        final rawMId = m['mId'] ?? m['mid'];
        if (rawMId == null) return <dynamic>[];
        final int mId = (rawMId as num).toInt();
        try {
          return await ApiService.getTasksForMilestone(mId);
        } catch (te) {
          debugPrint('Error fetching tasks for milestone $mId: $te');
          return <dynamic>[];
        }
      }).toList();

      allRawTasks = await Future.wait(taskFutures);

      // ── Step 2: Parse project start date (handles ISO or human format) ──
      final DateTime projectStart = _parseAnyDate(_project!.stDt);

      // ── Step 3: Parse Gantt data (setup) ──
      final List<GanttItemModel> ganttModels = [];
      DateTime pStart = projectStart;
      Map<String, String> milestoneMap = {};
      
      if (rawGantt.isNotEmpty) {
        var prjItem = rawGantt.firstWhere((item) => item['type'] == 'project', orElse: () => null);
        if (prjItem != null && prjItem['startDate'] != null) {
          pStart = _parseAnyDate(prjItem['startDate'].toString(), projectStart);
        }

        for (var item in rawGantt) {
          if (item['type'] == 'milestone') {
            milestoneMap[item['id'].toString()] = item['name']?.toString() ?? '';
          }
        }
      }

      // ── Step 4: Build UI models from results ───────────────────────────
      final List<MilestoneModel> milestoneModels = [];
      final List<TaskModel> taskModels = [];
      final List<TaskModel> unfilteredTaskModels = [];

      for (int mi = 0; mi < rawMilestones.length; mi++) {
        final m = rawMilestones[mi];
        final rawMId = m['mId'] ?? m['mid'];
        if (rawMId == null) continue;
        final int mId = (rawMId as num).toInt();

        final String title    = m['mlstnTtl']?.toString() ?? '';
        final String desc     = m['mlstnDesc']?.toString() ?? '';
        final String stDtRaw  = m['stDt']?.toString() ?? '';
        final String endDtRaw = m['endDt']?.toString() ?? '';
        final String sts      = (m['mlstnSts']?.toString() ?? 'LIVE').toUpperCase().trim();
        final String stDtDisplay  = _formatDbDate(stDtRaw);
        final String endDtDisplay = _formatDbDate(endDtRaw);

        final rawTasks = allRawTasks[mi];
        
        // Populate unfiltered task models for Gantt matching
        for (var t in rawTasks) {
          final String tIdUnfiltered     = t['taskId']?.toString() ?? '';
          final String tNameUnfiltered   = t['taskNm']?.toString() ?? '';
          final String tStatusUnfiltered = (t['taskSts']?.toString() ?? 'OPEN').toUpperCase();
          final String tCdUnfiltered     = t['taskCd']?.toString() ?? 'T-$tIdUnfiltered';
          final String tEndRawUnfiltered = t['endDt']?.toString() ?? '';
          final taskItemUnfiltered = TaskItem.fromJson(t, _project!, m, currentEmpId?.toString());
          
          Color statusColorUnfiltered = const Color(0xffF59E0B);
          double progressUnfiltered = 0.0;
          switch (tStatusUnfiltered) {
            case 'WIP':
            case 'INPROGRESS':
            case 'IN PROGRESS':
              statusColorUnfiltered = const Color(0xff2563EB); progressUnfiltered = 0.5;
              break;
            case 'COMPLETED':
            case 'DONE':
              statusColorUnfiltered = const Color(0xff10B981); progressUnfiltered = 1.0;
              break;
            case 'SUBMIT_REVIEW':
            case 'UNDER_REVIEW':
            case 'UNDERREVIEW':
              statusColorUnfiltered = const Color(0xff7C3AED); progressUnfiltered = 0.8;
              break;
            case 'REASSIGN':
              statusColorUnfiltered = const Color(0xFF4F46E5); progressUnfiltered = 0.4;
              break;
            case 'OVERDUE':
              statusColorUnfiltered = const Color(0xffB91C1C); progressUnfiltered = 0.5;
              break;
            case 'REWORK':
              statusColorUnfiltered = const Color(0xffEF4444); progressUnfiltered = 0.3;
              break;
            default:
              statusColorUnfiltered = const Color(0xffF59E0B); progressUnfiltered = 0.0;
              break;
          }
          
          unfilteredTaskModels.add(TaskModel(
            code: tCdUnfiltered,
            name: tNameUnfiltered,
            assignedTo: 'Assigned',
            priority: taskItemUnfiltered.priority,
            dueDate: _formatDbDate(tEndRawUnfiltered),
            status: tStatusUnfiltered,
            progress: progressUnfiltered,
            priorityColor: taskItemUnfiltered.tagColor,
            statusColor: statusColorUnfiltered,
            taskItem: taskItemUnfiltered,
            milestoneTitle: title,
          ));
        }

        final List<dynamic> filteredTasks = [];
        for (var t in rawTasks) {
          if (filterByEmp) {
            final tempItem = TaskItem.fromJson(t, _project!, m, currentEmpId.toString());
            final doerId = tempItem.rawData?['empId']?.toString() ?? tempItem.rawData?['empid']?.toString();
            final strEmpId = currentEmpId.toString();
            
            final noteTxt = (tempItem.rawData?['noteTxt'] ?? tempItem.rawData?['note_txt'] ?? '').toString();
            final isTeamMember = noteTxt.split(',').map((e) => e.trim()).contains(strEmpId);
            
            if (doerId == strEmpId || tempItem.reviewer == strEmpId || tempItem.approver == strEmpId || isTeamMember) {
               filteredTasks.add(t);
            }
          } else {
            filteredTasks.add(t);
          }
        }

        int openCount = 0;
        int completedCount = 0;

        for (var t in filteredTasks) {
          final String tId     = t['taskId']?.toString() ?? '';
          final String tName   = t['taskNm']?.toString() ?? '';
          final String tStatus = (t['taskSts']?.toString() ?? 'OPEN').toUpperCase();
          final String tCd     = t['taskCd']?.toString() ?? 'T-$tId';
          final String tStRaw  = t['stDt']?.toString() ?? '';
          final String tEndRaw = t['endDt']?.toString() ?? '';

          // Parse noOfDays safely
          int tDays = 3;
          final rawDays = t['noOfDays'];
          if (rawDays is num) {
            tDays = rawDays.toInt();
          } else if (rawDays is String) {
            tDays = int.tryParse(rawDays) ?? 3;
          }

          // Friendly status + progress
          String friendlyStatus = 'Open';
          Color statusColor = const Color(0xffF59E0B);
          double progress = 0.0;
          
          switch (tStatus) {
            case 'WIP':
            case 'INPROGRESS':
            case 'IN PROGRESS':
              friendlyStatus = 'In Progress'; statusColor = const Color(0xff2563EB); progress = 0.5;
              break;
            case 'COMPLETED':
            case 'CLOSED':
            case 'DONE':
              friendlyStatus = 'Closed'; statusColor = const Color(0xff10B981); progress = 1.0;
              break;
            case 'SUBMIT_REVIEW':
            case 'UNDER_REVIEW':
            case 'UNDERREVIEW':
              friendlyStatus = 'Under Review'; statusColor = const Color(0xff7C3AED); progress = 0.8;
              break;
            case 'REASSIGN':
              friendlyStatus = 'Reassign'; statusColor = const Color(0xFF4F46E5); progress = 0.4;
              break;
            case 'OVERDUE':
              friendlyStatus = 'Overdue'; statusColor = const Color(0xffB91C1C); progress = 0.5;
              break;
            case 'REWORK':
              friendlyStatus = 'Rework'; statusColor = const Color(0xffEF4444); progress = 0.3;
              break;
            default: // OPEN
              friendlyStatus = 'Open'; statusColor = const Color(0xffF59E0B); progress = 0.0;
              break;
          }

          // Status counts
          if (progress >= 1.0) {
            completedCount++;
          } else {
            openCount++;
          }

          // Gantt: use real start/end dates from DB
          int ganttStart = 1;
          int ganttDuration = tDays.clamp(1, 9999);
          if (tStRaw.isNotEmpty) {
            try {
              final ts = _parseAnyDate(tStRaw, projectStart);
              ganttStart = ts.difference(projectStart).inDays + 1;
              if (ganttStart < 1) ganttStart = 1;
            } catch (_) {}
          }
          if (tStRaw.isNotEmpty && tEndRaw.isNotEmpty) {
            try {
              final ts = _parseAnyDate(tStRaw, projectStart);
              final te = _parseAnyDate(tEndRaw, projectStart);
              final diff = te.difference(ts).inDays;
              if (diff >= 0) ganttDuration = diff + 1;
            } catch (_) {}
          }

          final taskItem = TaskItem.fromJson(t, _project!, m, currentEmpId?.toString());
          taskModels.add(TaskModel(
            code: tCd,
            name: tName,
            assignedTo: 'Assigned',
            priority: taskItem.priority,
            dueDate: _formatDbDate(tEndRaw),
            status: friendlyStatus,
            progress: progress,
            priorityColor: taskItem.tagColor,
            statusColor: statusColor,
            taskItem: taskItem,
            milestoneTitle: title,
          ));

          if (rawGantt.isEmpty) {
            ganttModels.add(GanttItemModel(
              id: tId,
              milestoneName: title,
              taskName: tName,
              progress: '${(progress * 100).toInt()}%',
              startDay: ganttStart,
              durationDays: ganttDuration,
              color: statusColor,
            ));
          }
        }

        // Milestone progress = completed / total tasks
        final int progressPercent = filteredTasks.isEmpty
            ? 0
            : ((completedCount / filteredTasks.length) * 100).round();

        milestoneModels.add(MilestoneModel(
          id: mId.toString(),
          title: title,
          desc: desc,
          startDate: stDtDisplay,
          targetDate: endDtDisplay,
          progress: progressPercent,
          assigned: filteredTasks.length,
          open: openCount,
          status: (sts == 'COMPLETED' || sts == 'CLOSED')
              ? 'Closed'
              : sts == 'HOLD'
                  ? 'On Hold'
                  : 'In Progress',
          color: (sts == 'COMPLETED' || sts == 'CLOSED')
              ? const Color(0xff10B981)
              : sts == 'HOLD'
                  ? const Color(0xffF59E0B)
                  : const Color(0xff2563EB),
        ));
      }

      // ── Step 5: Parse Gantt tasks using all tasks ──
      if (rawGantt.isNotEmpty) {
        
        for (var item in rawGantt) {
          if (item['type'] == 'task') {
            final String tId = item['id']?.toString() ?? '';
            final String tName = item['name']?.toString() ?? '';
            
            // Match against unfiltered task models to get the correct metadata/status
            TaskModel? matchingTask;
            final String cleanTId = tId.replaceAll(RegExp(r'[^0-9]'), '');
            for (var t in unfilteredTaskModels) {
              final String modelId = t.taskItem.id.toString();
              final String cleanModelId = modelId.replaceAll(RegExp(r'[^0-9]'), '');
              if ((cleanTId.isNotEmpty && cleanTId == cleanModelId) || t.name.toLowerCase() == tName.toLowerCase()) {
                matchingTask = t;
                break;
              }
            }

            final double progVal = (item['progress'] as num?)?.toDouble() ?? 0.0;
            final String progText = '${(progVal * 100).toInt()}%';

            final String parentId = item['parent']?.toString() ?? '';
            final String msName = milestoneMap[parentId] ?? 'Other';

            final String stDtRaw = item['startDate']?.toString() ?? '';
            final String endDtRaw = item['endDate']?.toString() ?? '';

            int ganttStart = 1;
            int ganttDuration = 3;

            if (stDtRaw.isNotEmpty) {
              try {
                final ts = _parseAnyDate(stDtRaw, pStart);
                ganttStart = ts.difference(pStart).inDays + 1;
                if (ganttStart < 1) ganttStart = 1;
              } catch (_) {}
            }
            if (stDtRaw.isNotEmpty && endDtRaw.isNotEmpty) {
              try {
                final ts = _parseAnyDate(stDtRaw, pStart);
                final te = _parseAnyDate(endDtRaw, pStart);
                final diff = te.difference(ts).inDays;
                if (diff >= 0) {
                  ganttDuration = diff + 1;
                }
              } catch (_) {}
            }

            Color statusColor = const Color(0xff2563EB); // Default to blue
            if (matchingTask != null) {
              statusColor = matchingTask.statusColor;
            } else {
              // Fallback based on progress
              if (progVal >= 1.0) {
                statusColor = const Color(0xff10B981); // Closed
              } else if (progVal > 0.0) {
                statusColor = const Color(0xff2563EB); // In progress
              } else {
                statusColor = const Color(0xffF59E0B); // Open
              }
            }

            ganttModels.add(GanttItemModel(
              id: tId,
              milestoneName: msName,
              taskName: tName,
              progress: progText,
              startDay: ganttStart,
              durationDays: ganttDuration,
              color: statusColor,
            ));
          }
        }
      }


      if (mounted) {
        setState(() {
          _milestones = milestoneModels;
          _tasks     = taskModels;
          _ganttData = ganttModels;
          _ganttProjectStart = pStart; // Store the parsed project start date used in Gantt
          _leadLagStatus = leadLag;
          _userDepartment = userDept;
          _milestoneNames = [
            'All Milestones',
            ...milestoneModels.map((m) => m.title),
          ];
          if (_selectedMilestoneTitle == null && milestoneModels.isNotEmpty) {
            _selectedMilestoneTitle = milestoneModels.first.title;
          } else if (milestoneModels.isNotEmpty && !milestoneModels.any((m) => m.title == _selectedMilestoneTitle)) {
            _selectedMilestoneTitle = milestoneModels.first.title;
          }
          _isLoading = false;
        });
        _fetchProjectDocuments();
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

  /// Parses any date string: ISO "2025-05-01" or human "01 May 2025" or "May 1, 2025".
  /// Falls back to [DateTime.now] if parsing fails.
  static DateTime _parseAnyDate(String raw, [DateTime? fallback]) {
    if (raw.isEmpty) return fallback ?? DateTime.now();
    // Try ISO first (fast path)
    try { return DateTime.parse(raw); } catch (_) {}
    // Try human format: "01 May 2025" or "1 May 2025" or with hyphens/slashes
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final cleanRaw = raw.trim().replaceAll('-', ' ').replaceAll('/', ' ');
    final parts = cleanRaw.split(RegExp(r'[\s,]+'));
    if (parts.length >= 3) {
      // "DD Mon YYYY"
      final day   = int.tryParse(parts[0]);
      final month = months[parts[1].toLowerCase().substring(0, 3)];
      final year  = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
      // "Mon DD YYYY"
      final mAlt = months[parts[0].toLowerCase().substring(0, 3)];
      final dAlt = int.tryParse(parts[1].replaceAll(',', ''));
      final yAlt = int.tryParse(parts[2]);
      if (mAlt != null && dAlt != null && yAlt != null) {
        return DateTime(yAlt, mAlt, dAlt);
      }
    }
    return fallback ?? DateTime.now();
  }

  double get _projectProgressValue {
    if (_tasks.isNotEmpty) {
      double totalWeighted = 0.0;
      for (final t in _tasks) {
        totalWeighted += t.progress;
      }
      return totalWeighted / _tasks.length;
    }
    if (_project != null && _project!.rawProgressValue != null) {
      final double val = _project!.rawProgressValue!;
      return val > 1.0 ? val / 100.0 : val;
    }
    return 0.0;
  }

  String get _projectProgressText {
    if (_tasks.isEmpty && _project != null && _project!.progressText.isNotEmpty && _project!.progressText != '0%') {
      return _project!.progressText;
    }
    return '${(_projectProgressValue * 100).round()}%';
  }

  Color get _projectProgressColor {
    final double val = _projectProgressValue;
    if (val < 0.5) {
      return const Color(0xffF97316); // Orange for < 50%
    } else if (val < 1.0) {
      return const Color(0xff3B82F6); // Blue for >= 50% and < 100%
    } else {
      return const Color(0xff22C55E); // Green for 100%
    }
  }

  List<GanttItemModel> get _currentTasks {
    if (_selectedMilestone == "All Milestones") {
      return _ganttData;
    } else {
      return _ganttData.where((item) => item.milestoneName == _selectedMilestone).toList();
    }
  }

  void _updateZoom(double newDayWidth) {
    setState(() {
      _baseDayWidth = newDayWidth.clamp(14.0, 80.0);
      _zoomPercent = ((_baseDayWidth / 40) * 100).roundToDouble();
    });
  }

  String _getGanttMonthYearHeader() {
    if (_project == null) return 'May, 2025';
    final DateTime projectStart = _parseAnyDate(_project!.stDt);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[projectStart.month - 1]}, ${projectStart.year}';
  }

  /// Converts a DB ISO LocalDate string ("yyyy-MM-dd") or datetime to a
  /// user-friendly display string like "26 Jun 2025". Returns raw value if parsing fails.
  static String _formatDbDate(String raw) {
    if (raw.isEmpty) return 'No Date';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  // Priority color mapping method
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return const Color(0xFF2563EB); // Blue
      case 'normal':
        return const Color(0xFF10B981); // Green
      case 'medium':
        return const Color(0xFFFACC15); // Yellow
      case 'high':
        return const Color(0xFF7C3AED); // Purple
      case 'critical':
        return const Color(0xFFEF4444); // Red
      case 'atmost critical':
        return const Color(0xFF722F37); // Wine
      default:
        return const Color(0xFF64748B);
    }
  }

  bool _isTaskAssignedToMe(TaskModel task) {
    if (_currentEmpId == null) return false;
    final tItem = task.taskItem;
    
    final doerId = tItem.rawData?['empId']?.toString() ?? tItem.rawData?['empid']?.toString();
    if (doerId == _currentEmpId.toString()) return true;
    
    if (tItem.reviewer == _currentEmpId.toString()) return true;
    if (tItem.approver == _currentEmpId.toString()) return true;
    
    return false;
  }

  Future<void> _downloadReport() async {
    if (_project == null) return;

    try {
      final prjName = _project?.prjNm ?? 'N/A';
      final prjCode = _project?.prjCd ?? 'N/A';
      final company = _project?.companyName ?? 'N/A';
      final plant = _project?.plantName ?? 'N/A';
      final locationText = _project?.location ?? _projectLocation;
      final status = _project?.prjSts ?? 'N/A';
      
      final buffer = StringBuffer();
      buffer.writeln("==================================================");
      buffer.writeln("              PROJECT STATUS REPORT");
      buffer.writeln("==================================================");
      buffer.writeln("Project Name:  $prjName");
      buffer.writeln("Project Code:  $prjCode");
      buffer.writeln("Company:       $company");
      buffer.writeln("Plant:         $plant");
      buffer.writeln("Location:      $locationText");
      buffer.writeln("Status:        $status");
      buffer.writeln("==================================================\n");

      buffer.writeln("==================================================");
      buffer.writeln("                   MILESTONES");
      buffer.writeln("==================================================");
      if (_milestones.isEmpty) {
        buffer.writeln("No milestones found.");
      } else {
        for (int i = 0; i < _milestones.length; i++) {
          final m = _milestones[i];
          buffer.writeln("${i + 1}. ${m.title}");
          buffer.writeln("   - Status:      ${m.status}");
          buffer.writeln("   - Start Date:  ${m.startDate}");
          buffer.writeln("   - Target Date: ${m.targetDate}");
          buffer.writeln("   - Progress:    ${m.progress}%");
          buffer.writeln("   - Tasks:       ${m.assigned} Assigned, ${m.open} Open");
          buffer.writeln("   - Description: ${m.desc}");
          buffer.writeln();
        }
      }
      buffer.writeln("==================================================\n");

      buffer.writeln("==================================================");
      buffer.writeln("                 DETAILED TASKS");
      buffer.writeln("==================================================");
      if (_tasks.isEmpty) {
        buffer.writeln("No tasks found.");
      } else {
        for (int i = 0; i < _tasks.length; i++) {
          final t = _tasks[i];
          buffer.writeln("${i + 1}. [${t.code}] ${t.name}");
          buffer.writeln("   - Milestone:   ${t.milestoneTitle}");
          buffer.writeln("   - Due Date:    ${t.dueDate}");
          buffer.writeln("   - Priority:    ${t.priority}");
          buffer.writeln("   - Status:      ${t.status}");
          buffer.writeln("   - Progress:    ${(t.progress * 100).toInt()}%");
          buffer.writeln();
        }
      }
      buffer.writeln("==================================================");
      buffer.writeln("Generated on:  ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}");
      buffer.writeln("==================================================");

      final reportContent = buffer.toString();
      final bytes = Uint8List.fromList(utf8.encode(reportContent));

      final String fileName = "Project_Report_${prjCode.replaceAll(RegExp(r'[^\w-]'), '_')}.txt";

      final path = await FilePicker.saveFile(
        dialogTitle: 'Save Project Report',
        fileName: fileName,
        bytes: bytes,
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved successfully to: $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save report cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error exporting report: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { setState(() {}); });
  }

  /// Called once after initState and whenever a dependency changes.
  /// Route arguments (ProjectModel) are available here — safe to fetch.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isProjectLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ProjectModel) {
        _project = args;
        _leadLagStatus = args.leadLagStatusStr;
      } else if (args is Map) {
        final mapArgs = Map<String, dynamic>.from(args);
        if (mapArgs['project'] is ProjectModel) {
          _project = mapArgs['project'] as ProjectModel;
          _leadLagStatus = _project!.leadLagStatusStr;
        }
        if (mapArgs['initialTab'] != null) {
          final int initTab = (mapArgs['initialTab'] as num).toInt();
          if (initTab >= 0 && initTab < 4) {
            _tabController.index = initTab;
          }
        }
      }
      _isProjectLoaded = true;
      _fetchProjectData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFBFC),
      appBar: CustomHeader(
        title: 'Project Details',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchNotificationCount();
        },
      ),
      body: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80.0),
                child: CircularProgressIndicator(),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load project data',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchProjectData,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Color(0xFF1E293B),
                    ),
                    label: const Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _downloadReport,
                    icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                    label: const Text('Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),
            _buildProjectBannerCard(),
            _buildTabBar(),
            Padding(
              padding: _tabController.index == 2
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _tabController.index == 0
                  ? _buildOverviewTabContent()
                  : _tabController.index == 1
                      ? _buildMilestonesTabContent()
                      : _tabController.index == 2
                          ? _buildGanttChartTabContent()
                          : _tabController.index == 3
                              ? _buildDocumentsTabContent()
                              : _buildEmptyStateTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  Widget _buildProjectImage(String? logoPath, String projectNm, double size) {
    if (logoPath == null || logoPath.isEmpty) {
      return _buildPlaceholderImage(projectNm, size);
    }

    final String fullImageUrl = (logoPath.startsWith('http://') || logoPath.startsWith('https://'))
        ? logoPath
        : '${dotenv.env['BASE_URL'] ?? 'https://bionova-rjii.onrender.com'}/${logoPath.startsWith('/') ? logoPath.substring(1) : logoPath}';

    return Image.network(
      fullImageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: size,
          height: size,
          color: const Color(0xffF8FAFC),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff10B981)),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderImage(projectNm, size);
      },
    );
  }

  Widget _buildPlaceholderImage(String name, double size) {
    final String char = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final List<Color> colors = [
      const Color(0xff3B82F6),
      const Color(0xff1D4ED8),
    ];
    if (char.codeUnitAt(0) % 2 == 0) {
      colors[0] = const Color(0xff10B981);
      colors[1] = const Color(0xff047857);
    } else if (char.codeUnitAt(0) % 3 == 0) {
      colors[0] = const Color(0xff8B5CF6);
      colors[1] = const Color(0xff6D28D9);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==================== UPDATED PROJECT BANNER CARD - PRIORITY REMOVED FROM TOP ====================
  Widget _buildProjectBannerCard() {
    final String prjName = _project?.prjNm ?? 'No Project Name';
    final String prjPriority = _project?.prjPrty ?? 'Medium';
    final String companyName = _project?.companyName ?? '';
    final String plantName = _project?.plantName ?? '';
    final String location = _project?.location ?? _projectLocation;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xff10B981).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP SECTION - Priority badge removed
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildProjectImage(_project?.logo, prjName, 90),
                ),
                const SizedBox(width: 14),
                // Project Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prjName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xff0F172A),
                          height: 1.2,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      if (companyName.isNotEmpty)
                        Text(
                          companyName,
                          style: const TextStyle(fontSize: 11, color: Color(0xff64748B), fontWeight: FontWeight.w600),
                        ),
                      if (plantName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            plantName,
                            style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                          ),
                        ),
                      if (location.isNotEmpty && location != 'Loading Location...')
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xff64748B)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(fontSize: 10, color: Color(0xff64748B), fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Priority badge REMOVED from here
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Progress Circle
                Column(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _projectProgressValue,
                            strokeWidth: 3,
                            backgroundColor: const Color(0xffF1F5F9),
                            color: _projectProgressColor,
                          ),
                          Text(
                            _projectProgressText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _projectProgressColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Footer section
          _buildCardFooter(),
        ],
      ),
    );
  }

  // Footer section
  Widget _buildCardFooter() {
    final String status = (_project?.prjSts ?? '').trim().toUpperCase();
    final bool isCompleted = status == 'CLOSED' || status == 'COMPLETED' || status == 'DONE' || _projectProgressValue >= 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xff10B981).withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xff10B981).withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Start Date, Target Date
          Row(
            children: [
              _buildTopMetaItem(
                'Start Date',
                _project?.stDt != null ? _formatDbDate(_project!.stDt) : 'N/A',
                Icons.calendar_today_outlined,
                iconColor: Colors.green,
              ),
              Container(
                height: 20,
                width: 1,
                color: const Color(0xff10B981).withValues(alpha: 0.20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildTopMetaItem(
                'End Date',
                _project?.endDt != null ? _formatDbDate(_project!.endDt) : 'N/A',
                Icons.event_outlined,
                iconColor: Colors.orange,
              ),
            ],
          ),
          if (isCompleted)
            _buildLeadLagBadge(_leadLagStatus)
          else
            _buildPriorityPill(_project?.prjPrty ?? 'Medium', getPriorityColor(_project?.prjPrty ?? 'Medium')),
        ],
      ),
    );
  }

  Widget _buildTopMetaItem(
    String label,
    String value,
    IconData icon, {
    Color iconColor = Colors.blue,
    Color textColor = const Color(0xff1E293B),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xff64748B))),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        )
      ],
    );
  }

  // Helper widgets
  Widget _buildPriorityPill(String? priority, Color priorityColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            priority?.toUpperCase() ?? 'NORMAL',
            style: TextStyle(
              color: priorityColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadLagBadge(String statusStr) {
    final String s = statusStr.trim().toLowerCase();
    
    // Ensure null, 'null', 'n/a', or empty values default to 'On Time' instead of rendering 'null'
    if (s == 'null' || s == 'n/a' || s.isEmpty || s == 'none') {
      return _buildLeadLagPill('On Time', const Color(0xffDBEAFE), const Color(0xff2563EB));
    }

    bool isLead = s.contains('lead') || s == 'ahead';
    bool isLag = s.contains('lag') || s == 'behind' || s == 'delay';

    if (isLead) {
      return _buildLeadLagPill('Lead', const Color(0xffDCFCE7), const Color(0xff16A34A));
    } else if (isLag) {
      return _buildLeadLagPill('Lag', const Color(0xffFEE2E2), const Color(0xffDC2626));
    } else {
      return _buildLeadLagPill('On Time', const Color(0xffDBEAFE), const Color(0xff2563EB));
    }
  }

  Widget _buildLeadLagPill(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  // ==================== END OF UPDATED TOP SECTION ====================

  Widget _buildGanttChartTabContent() {
    double currentDayWidth = _baseDayWidth * _scaleFactor;
    if (currentDayWidth < 14) currentDayWidth = 14;
    if (currentDayWidth > 80) currentDayWidth = 80;

    final List<GanttItemModel> tasks = _currentTasks;

    // Calculate max day from tasks and project duration
    int taskMaxDay = tasks.isEmpty ? 0 : tasks.map((e) => e.startDay + e.durationDays - 1).reduce((a, b) => a > b ? a : b);
    int projectMaxDay = 30;
    if (_project != null && _project!.stDt.isNotEmpty && _project!.endDt.isNotEmpty) {
      try {
        final pStart = _parseAnyDate(_project!.stDt);
        final pEnd = _parseAnyDate(_project!.endDt);
        projectMaxDay = pEnd.difference(pStart).inDays;
      } catch (_) {}
    }
    
    final int maxDay = [taskMaxDay, projectMaxDay, 30].reduce((a, b) => a > b ? a : b) + 5; // Add 5 days buffer

    // Generate visible days based on max day
    final List<int> visibleDays = List.generate(maxDay, (index) => index + 1);
    
    final DateTime projectStart = _ganttProjectStart ?? (_project != null ? _parseAnyDate(_project!.stDt) : DateTime.now());
    const List<String> shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final double totalGanttTimelineWidth = visibleDays.length * currentDayWidth;

    // Calculate exact heights
    final int rowCount = tasks.isEmpty ? 1 : tasks.length;
    final double stackHeight = rowCount * rowHeight;

    return GestureDetector(
      onScaleUpdate: (ScaleUpdateDetails details) {
        setState(() {
          _scaleFactor = details.scale;
        });
      },
      onScaleEnd: (ScaleEndDetails details) {
        double newWidth = _baseDayWidth * _scaleFactor;
        _updateZoom(newWidth);
        _scaleFactor = 1.0;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controls Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedMilestone,
                      underline: const SizedBox(),
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E293B),
                      ),
                      items: _milestoneNames.map((String value) {
                        Color color;
                        if (value == "All Milestones") {
                          color = const Color(0xff64748B);
                        } else if (value == "Project Initiation") {
                          color = const Color(0xff10B981);
                        } else {
                          color = const Color(0xff2563EB);
                        }
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedMilestone = value!;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Color(0xff2563EB)),
                  onPressed: () => _updateZoom(_baseDayWidth - 3),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                ),
                Text(
                  '${_zoomPercent.round()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Color(0xff2563EB)),
                  onPressed: () => _updateZoom(_baseDayWidth + 3),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong, size: 16, color: Color(0xff64748B)),
                  onPressed: () => _updateZoom(28.0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 16,
                ),
              ],
            ),
          ),

          // Gantt Chart
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalGanttTimelineWidth,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        height: ganttHeaderHeight,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xffF8FAFC),
                          border: Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getGanttMonthYearHeader(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: visibleDays.map((day) {
                                final date = projectStart.add(Duration(days: day - 1));
                                final bool showMonth = currentDayWidth >= 20;
                                final dateText = showMonth ? '${date.day}\n${shortMonths[date.month - 1]}' : '${date.day}';

                                return SizedBox(
                                  width: currentDayWidth,
                                  child: Center(
                                    child: Text(
                                      dateText,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: currentDayWidth < 18 ? 7 : 9,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff64748B),
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ),

                      // Timeline Grid with Bars
                      SizedBox(
                        height: stackHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Grid lines
                            Column(
                              children: List.generate(rowCount, (index) {
                                return Container(
                                  height: rowHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: index == rowCount - 1 ? Colors.transparent : const Color(0xffF1F5F9),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: visibleDays.map((_) {
                                      return Container(
                                        width: currentDayWidth,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: const Color(0xffF1F5F9),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }),
                            ),

                            // Task Bars
                            ...tasks.asMap().entries.map((entry) {
                              final index = entry.key;
                              final task = entry.value;
                              final startPos = (task.startDay - 1) * currentDayWidth;
                              final barWidth = (task.durationDays * currentDayWidth - 4).clamp(20.0, double.infinity);
                              final Color taskColor = task.color;

                              return Positioned(
                                top: index * rowHeight + (rowHeight - barHeight) / 2,
                                left: startPos + 2,
                                child: SizedBox(
                                  width: barWidth,
                                  height: barHeight + 25,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Main Bar
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: Container(
                                          width: barWidth,
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: taskColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            task.taskName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: barWidth < 60 ? 8 : 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      
                                      // Progress
                                      Positioned(
                                        top: 2,
                                        right: 4,
                                        child: Text(
                                          task.progress,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildGanttLegend('Open', const Color(0xffF59E0B)),
                _buildGanttLegend('In Progress', const Color(0xff2563EB)),
                _buildGanttLegend('Under Review', const Color(0xff7C3AED)),
                _buildGanttLegend('Reassign', const Color(0xFF4F46E5)),
                _buildGanttLegend('Closed', const Color(0xff10B981)),
                _buildGanttLegend('Overdue', const Color(0xffB91C1C)),
                _buildGanttLegend('Rework', const Color(0xffEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGanttLegend(String label, Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xff475569), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffE2E8F0), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xff2563EB),
        labelColor: const Color(0xff2563EB),
        unselectedLabelColor: const Color(0xff64748B),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Milestones & Tasks'),
          Tab(text: 'Gantt Chart'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }

  Widget _buildOverviewTabContent() {
    return Column(
      children: [
        _buildProjectInformationCard(),
        const SizedBox(height: 12),
        _buildProjectProgressCard(),
        const SizedBox(height: 12),
        _buildMyRoleCard(),
        const SizedBox(height: 12),
        _buildTaskSummaryCard(),
        const SizedBox(height: 12),
        _buildUpcomingMilestonesCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMilestonesTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.layers_outlined, size: 18, color: Color(0xff2563EB)),
                  SizedBox(width: 8),
                  Text('PROJECT MILESTONES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xffF1F5F9), thickness: 1),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _milestones.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final milestone = _milestones[index];
                  bool isCompleted = milestone.status == "Closed" || milestone.status == "Completed";
                  bool isSelected = milestone.title == _selectedMilestoneTitle;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMilestoneTitle = milestone.title;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xffEFF6FF) : const Color(0xffF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xff3B82F6) : const Color(0xffE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted ? const Color(0xffE8F8EC) : milestone.color.withValues(alpha: 0.1),
                              border: Border.all(color: milestone.color, width: 1),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 12, color: Color(0xff10B981))
                                  : Text(milestone.id, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: milestone.color)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(milestone.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xff0F172A))),
                                const SizedBox(height: 2),
                                Text(milestone.desc, style: const TextStyle(fontSize: 10, color: Color(0xff64748B))),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text('Start: ${milestone.startDate}', style: const TextStyle(fontSize: 9.5, color: Color(0xff475569))),
                                    Text('Due: ${milestone.targetDate}', style: const TextStyle(fontSize: 9.5, color: Color(0xff475569))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text('Assigned: ${milestone.assigned}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xff1E293B))),
                                    Text('Open: ${milestone.open}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xff1E293B))),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: milestone.progress / 100,
                                      strokeWidth: 2.5,
                                      backgroundColor: const Color(0xffF1F5F9),
                                      color: milestone.color,
                                    ),
                                    Text('${milestone.progress}%', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCompleted ? const Color(0xffE8F8EC) : milestone.status == "In Progress" ? const Color(0xffEFF6FF) : const Color(0xffF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(milestone.status, style: TextStyle(color: milestone.color, fontSize: 8.5, fontWeight: FontWeight.w700)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildTasksAssignedSection(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTasksAssignedSection() {
    final allMilestoneTasks = _tasks.where((t) => t.milestoneTitle == _selectedMilestoneTitle).toList();
    final filteredTasks = _filterByEmp
        ? allMilestoneTasks.where((t) => _isTaskAssignedToMe(t)).toList()
        : allMilestoneTasks;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_outlined, size: 18, color: Color(0xff2563EB)),
              SizedBox(width: 8),
              Text('TASKS ASSIGNED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Milestone: ${_selectedMilestoneTitle ?? 'None'}',
            style: const TextStyle(fontSize: 9.5, color: Color(0xff64748B), fontWeight: FontWeight.w600),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xffF1F5F9), thickness: 1),
          ),
          if (filteredTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No tasks assigned to you under this milestone',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTasks.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xffF8FAFC), height: 16),
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/task-details',
                      arguments: task.taskItem,
                    ).then((_) => _fetchProjectData());
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(task.priority, style: TextStyle(color: task.priorityColor, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(task.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff0F172A))),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (() {
                                  final String roleText = task.code == 'PRJ-001-T03' ? 'Reviewer' : task.code == 'PRJ-001-T04' ? 'Approver' : 'Executor';
                                  Color roleBg;
                                  Color roleTextCol;
                                  Color roleBorder;
                                  
                                  if (roleText == 'Reviewer') {
                                    roleBg = const Color(0xffF3E8FF);
                                    roleTextCol = const Color(0xff7C3AED);
                                    roleBorder = const Color(0xffE9D5FF);
                                  } else if (roleText == 'Approver') {
                                    roleBg = const Color(0xffFFF7ED);
                                    roleTextCol = const Color(0xffEA580C);
                                    roleBorder = const Color(0xffFED7AA);
                                  } else {
                                    roleBg = const Color(0xffEFF6FF);
                                    roleTextCol = const Color(0xff2563EB);
                                    roleBorder = const Color(0xffBFDBFE);
                                  }
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: roleBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: roleBorder),
                                    ),
                                    child: Text(
                                      'Role: $roleText',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        color: roleTextCol,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                })(),
                              ],
                            ),
                            Text('Due: ${task.dueDate}', style: const TextStyle(fontSize: 10.5, color: Color(0xff64748B))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: task.status == "In Progress" ? const Color(0xffEFF6FF) : const Color(0xffFFF7ED),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(task.status, style: TextStyle(color: task.statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: task.progress,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xffF1F5F9),
                                  color: const Color(0xff2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(task.progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildEmptyStateTabContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('Content Loading...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }


  Widget _buildTaskSummaryCard() {
    final totalCount = _tasks.length;
    final inProgressCount = _tasks.where((t) => t.status == 'In Progress').length;
    final openCount = _tasks.where((t) => t.status == 'Pending' || t.status == 'Open').length;
    final completedCount = _tasks.where((t) => t.status == 'Closed' || t.status == 'Completed').length;

    return _buildSectionCard(
      title: 'TASK SUMMARY',
      icon: Icons.assignment_outlined,
      iconColor: Colors.blue,
      actionWidget: InkWell(
        onTap: () {
          _tabController.animateTo(1);
        },
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'View all →',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
        ),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        children: [
          _buildTaskBlock('Tasks Assigned', '$totalCount', Icons.assignment_turned_in_outlined, const Color(0xff7C3AED)),
          _buildTaskBlock('In Progress', '$inProgressCount', Icons.play_circle_outline, Colors.blue),
          _buildTaskBlock('Open Tasks', '$openCount', Icons.query_builder, Colors.orange),
          _buildTaskBlock('Closed', '$completedCount', Icons.check_circle_outline, Colors.green),
        ],
      ),
    );
  }

  Widget _buildTaskBlock(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xff0F172A))),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: Color(0xff64748B), fontWeight: FontWeight.w500), maxLines: 1),
      ],
    );
  }

  Widget _buildProjectProgressCard() {
    final int total = _tasks.length;
    final int inProgress = _tasks.where((t) => t.status == 'In Progress' || t.status == 'Under Review' || t.status == 'Reassign' || t.status == 'Rework' || t.status == 'Overdue').length;
    final int yetToStart = _tasks.where((t) => t.status == 'Open' || t.status == 'Pending').length;
    final int completed = _tasks.where((t) => t.status == 'Closed' || t.status == 'Completed').length;

    double completedPct = 0.0;
    double inProgressPct = 0.0;
    double yetToStartPct = 0.0;

    if (total > 0) {
      completedPct = completed / total;
      inProgressPct = inProgress / total;
      yetToStartPct = yetToStart / total;
    }

    return _buildSectionCard(
      title: 'PROJECT PROGRESS',
      icon: Icons.pie_chart_outline,
      iconColor: Colors.blue,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 74,
                  height: 74,
                  child: CircularProgressIndicator(
                    value: completedPct,
                    strokeWidth: 8,
                    backgroundColor: Colors.orange,
                    color: Colors.green,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(completedPct * 100).round()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xff0F172A))),
                    const Text('Closed', style: TextStyle(fontSize: 8, color: Color(0xff64748B))),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildProgressLegend('Closed', '${(completedPct * 100).round()}%', Colors.green),
                _buildProgressLegend('In Progress', '${(inProgressPct * 100).round()}%', Colors.blue),
                _buildProgressLegend('Yet to Start', '${(yetToStartPct * 100).round()}%', Colors.orange),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressLegend(String status, String percent, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(status, style: const TextStyle(fontSize: 11, color: Color(0xff475569))),
            ],
          ),
          Text(percent, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff1E293B))),
        ],
      ),
    );
  }

  Widget _buildMyRoleCard() {
    return _buildSectionCard(
      title: 'MY ROLE',
      icon: Icons.person_outline,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildRowDetail('Role', 'Team Member'),
          _buildRowDetail('Department', _userDepartment),
        ],
      ),
    );
  }

  Widget _buildProjectInformationCard() {
    final String descText = (_project?.prjDesc != null && _project!.prjDesc.trim().isNotEmpty)
        ? _project!.prjDesc.trim()
        : 'No description provided.';

    return _buildSectionCard(
      title: 'PROJECT INFORMATION',
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRowDetail('Project Code', _project?.prjCd ?? 'N/A'),
          _buildRowDetail('Location', _project?.location ?? _projectLocation),
          _buildRowDetail('Company', _project?.companyName ?? 'N/A'),
          _buildRowDetail('Description', descText),
        ],
      ),
    );
  }

  Widget _buildUpcomingMilestonesCard() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final upcoming = _milestones.where((m) {
      if (m.status == 'Closed' || m.status == 'Completed') return false;
      try {
        final start = _parseAnyDate(m.startDate);
        final startDate = DateTime(start.year, start.month, start.day);
        return startDate.isAfter(todayDate) || startDate.isAtSameMomentAs(todayDate);
      } catch (_) {
        return m.status != 'Closed' && m.status != 'Completed';
      }
    }).toList();
    
    // Maintain sequential project order
    final upcomingLimit = upcoming.take(4).toList();

    return _buildSectionCard(
      title: 'UPCOMING MILESTONES',
      icon: Icons.flag_outlined,
      iconColor: Colors.blue,
      actionWidget: InkWell(
        onTap: () {
          _tabController.animateTo(1);
        },
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'View all →',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
        ),
      ),
      child: Column(
        children: upcomingLimit.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('No upcoming milestones', style: TextStyle(fontSize: 11, color: Colors.grey)),
                )
              ]
            : List.generate(upcomingLimit.length, (index) {
                final m = upcomingLimit[index];
                return _buildMilestoneRow(m.title, m.targetDate, m.color, isLast: index == upcomingLimit.length - 1);
              }),
      ),
    );
  }

  Widget _buildMilestoneRow(String title, String date, Color dotColor, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xffF1F5F9), width: 1))),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11.5, color: Color(0xff1E293B), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Text(date, style: const TextStyle(fontSize: 11, color: Color(0xff64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color iconColor, required Widget child, Widget? actionWidget}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xffE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xff1E293B), letterSpacing: 0.3)),
                ],
              ),
              if (actionWidget != null) actionWidget,
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xffF1F5F9), thickness: 1, height: 1)),
          child,
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xff64748B)))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: const Color(0xff1E293B)))),
        ],
      ),
    );
  }

  Future<void> _fetchProjectDocuments() async {
    if (_tasks.isEmpty) {
      if (mounted) {
        setState(() {
          _projectDocuments = [];
          _isLoadingDocuments = false;
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoadingDocuments = true;
      });
    }

    try {
      final List<Future<List<Map<String, dynamic>>>> futures = _tasks.map((t) async {
        final rawIdStr = t.taskItem.id;
        final int? taskId = int.tryParse(rawIdStr.toString());
        if (taskId == null) return <Map<String, dynamic>>[];
        
        final drftId = t.taskItem.drftTaskId != null
            ? int.tryParse(t.taskItem.drftTaskId.toString())
            : null;
            
        try {
          return await ApiService.fetchAttachmentsForTask(
            taskId: taskId,
            drftTaskId: drftId,
          );
        } catch (e) {
          debugPrint('Error fetching attachments for task $taskId: $e');
          return <Map<String, dynamic>>[];
        }
      }).toList();

      final List<List<Map<String, dynamic>>> results = await Future.wait(futures);
      final List<Map<String, dynamic>> docs = [];

      for (int i = 0; i < results.length; i++) {
        final task = _tasks[i];
        final taskDocs = results[i];
        for (final att in taskDocs) {
          final String fileName = att['fileNm'] ?? 'Attachment';
          final String ext = fileName.split('.').last.toLowerCase();

          IconData fileIcon = Icons.insert_drive_file;
          Color iconColor = Colors.blue;
          Color bgColor = const Color(0xFFEFF6FF);

          if (ext == 'pdf') {
            fileIcon = Icons.picture_as_pdf;
            iconColor = Colors.red;
            bgColor = const Color(0xFFFFF5F5);
          } else if (ext == 'xls' || ext == 'xlsx' || ext == 'csv') {
            fileIcon = Icons.table_chart;
            iconColor = Colors.green;
            bgColor = const Color(0xFFF0FDF4);
          } else if (ext == 'doc' || ext == 'docx') {
            fileIcon = Icons.description;
            iconColor = Colors.blue;
            bgColor = const Color(0xFFEFF6FF);
          } else if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
            fileIcon = Icons.image;
            iconColor = Colors.orange;
            bgColor = const Color(0xFFFFF7ED);
          }

          docs.add({
            'fileId': att['fileId'],
            'fileName': fileName,
            'size': 'Uploaded',
            'icon': fileIcon,
            'iconColor': iconColor,
            'bgColor': bgColor,
            'taskName': task.name,
            'milestoneName': task.milestoneTitle,
            'atPath': att['atPath'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _projectDocuments = docs;
          _isLoadingDocuments = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading project documents: $e');
      if (mounted) {
        setState(() {
          _isLoadingDocuments = false;
        });
      }
    }
  }

  void _downloadFile(String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Downloading $fileName...')),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue.shade700,
      ),
    );

    Future.delayed(const Duration(seconds: 1, milliseconds: 200), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $fileName downloaded successfully!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Widget _buildDocumentsTabContent() {
    if (_isLoadingDocuments) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xff2563EB)),
        ),
      );
    }

    if (_projectDocuments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No documents uploaded for this project',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.folder_outlined, size: 18, color: Color(0xff2563EB)),
              SizedBox(width: 8),
              Text('PROJECT DOCUMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xffF1F5F9), thickness: 1),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _projectDocuments.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xffF8FAFC), height: 16),
            itemBuilder: (context, index) {
              final doc = _projectDocuments[index];
              final fileName = doc['fileName'] as String;
              final taskName = doc['taskName'] as String;
              final milestoneName = doc['milestoneName'] as String;
              final icon = doc['icon'] as IconData;
              final iconColor = doc['iconColor'] as Color;
              final bgColor = doc['bgColor'] as Color;

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xffF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Milestone: $milestoneName | Task: $taskName',
                            style: const TextStyle(fontSize: 10, color: Color(0xff64748B)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _downloadFile(fileName),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.download_outlined,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}