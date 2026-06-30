import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  GanttItemModel({
    required this.id,
    required this.milestoneName,
    required this.taskName,
    required this.progress,
    required this.startDay,
    required this.durationDays,
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
  int _currentIndex = 1;

  // Scroll controller
  final ScrollController _horizontalScrollController = ScrollController();

  // Gantt Chart Matrix Constraints
  static const double rowHeight = 50.0;
  static const double barHeight = 28.0;
  static const double ganttHeaderHeight = 50.0;
  double _baseDayWidth = 28.0;
  double _scaleFactor = 1.0;
  double _zoomPercent = 70.0;

  // Selected task ID for highlighting
  String? _selectedTaskId;

  String _selectedMilestone = "All Milestones";
  List<String> _milestoneNames = ["All Milestones"];
  String? _selectedMilestoneTitle;

  List<MilestoneModel> _milestones = [];
  List<TaskModel> _tasks = [];
  List<GanttItemModel> _ganttData = [];

  ProjectModel? _project;
  bool _isProjectLoaded = false;
  bool _isLoading = true;
  String? _error;
  String _projectLocation = 'Loading Location...';

  Future<void> _fetchProjectData() async {
    if (_project == null) {
      setState(() { _isLoading = false; });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch plant location
      if (_project?.pltId != null && _project!.pltId! > 0) {
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

      List<dynamic> rawMilestones = [];
      List<List<dynamic>> allRawTasks = [];
      List<dynamic> rawGantt = [];

      if (filterByEmp) {
        final employeeMilestones = await ApiService.getMilestonesByEmployee(currentEmpId);
        rawMilestones = employeeMilestones.where((m) => m['prjId'] == _project!.prjId).toList();

        final employeeTasks = await ApiService.getTasksByEmployee(currentEmpId);
        for (var m in rawMilestones) {
          final rawMId = m['mId'] ?? m['mid'];
          if (rawMId == null) continue;
          final int mId = (rawMId as num).toInt();

          final mTasks = employeeTasks.where((t) {
            final rawTaskMId = t['mId'] ?? t['mid'];
            if (rawTaskMId == null) return false;
            return (rawTaskMId as num).toInt() == mId;
          }).toList();
          allRawTasks.add(mTasks);
        }
      } else {
        final results = await Future.wait([
          ApiService.getMilestones(_project!.prjId),
          ApiService.getGanttData(_project!.prjId),
        ]);
        rawMilestones = results[0] as List<dynamic>;
        rawGantt = results[1] as List<dynamic>;

        final List<Future<List<dynamic>>> taskFutures = rawMilestones.map((m) {
          final rawMId = m['mId'] ?? m['mid'];
          if (rawMId == null) return Future.value(<dynamic>[]);
          final int mId = (rawMId as num).toInt();
          return ApiService.getTasksForMilestone(mId);
        }).toList();

        allRawTasks = await Future.wait(taskFutures);
      }

      // ── Step 2: Parse project start date (handles ISO or human format) ──
      final DateTime projectStart = _parseAnyDate(_project!.stDt);

      // ── Step 3: Parse Gantt data ──
      final List<GanttItemModel> ganttModels = [];
      if (rawGantt.isNotEmpty) {
        var prjItem = rawGantt.firstWhere((item) => item['type'] == 'project', orElse: () => null);
        DateTime pStart = projectStart;
        if (prjItem != null && prjItem['startDate'] != null) {
          pStart = _parseAnyDate(prjItem['startDate'].toString(), projectStart);
        }

        Map<String, String> milestoneMap = {};
        for (var item in rawGantt) {
          if (item['type'] == 'milestone') {
            milestoneMap[item['id'].toString()] = item['name']?.toString() ?? '';
          }
        }

        for (var item in rawGantt) {
          if (item['type'] == 'task') {
            final String tId = item['id']?.toString() ?? '';
            final String tName = item['name']?.toString() ?? '';
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
                if (diff > 0) {
                  ganttDuration = diff;
                }
              } catch (_) {}
            }

            ganttModels.add(GanttItemModel(
              id: tId,
              milestoneName: msName,
              taskName: tName,
              progress: progText,
              startDay: ganttStart,
              durationDays: ganttDuration,
            ));
          }
        }
      }

      // ── Step 4: Build UI models from results ───────────────────────────
      final List<MilestoneModel> milestoneModels = [];
      final List<TaskModel> taskModels = [];

      for (int mi = 0; mi < rawMilestones.length; mi++) {
        final m = rawMilestones[mi];
        final rawMId = m['mId'] ?? m['mid'];
        if (rawMId == null) continue;
        final int mId = (rawMId as num).toInt();

        final String title    = m['mlstnTtl']?.toString() ?? '';
        final String desc     = m['mlstnDesc']?.toString() ?? '';
        final String stDtRaw  = m['stDt']?.toString() ?? '';
        final String endDtRaw = m['endDt']?.toString() ?? '';
        final String sts      = m['mlstnSts']?.toString() ?? 'LIVE';

        final String stDtDisplay  = _formatDbDate(stDtRaw);
        final String endDtDisplay = _formatDbDate(endDtRaw);

        final rawTasks = allRawTasks[mi];
        final List<dynamic> filteredTasks = [];
        for (var t in rawTasks) {
          if (filterByEmp) {
            final int? taskEmpId = t['empId'] != null ? (t['empId'] as num).toInt() : null;
            if (taskEmpId == currentEmpId) {
              filteredTasks.add(t);
            }
          } else {
            filteredTasks.add(t);
          }
        }

        if (filterByEmp && filteredTasks.isEmpty) {
          continue;
        }

        int openCount = 0;
        int completedCount = 0;

        for (var t in filteredTasks) {
          final String tId     = t['taskId']?.toString() ?? '';
          final String tName   = t['taskNm']?.toString() ?? '';
          final String tStatus = t['taskSts']?.toString() ?? 'OPEN';
          final String tCd     = t['taskCd']?.toString() ?? 'T-$tId';
          final String tStRaw  = t['stDt']?.toString() ?? '';
          final String tEndRaw = t['endDt']?.toString() ?? '';

          // Parse noOfDays safely
          int tDays = 3;
          final rawDays = t['noOfDays'];
          if (rawDays is num) tDays = rawDays.toInt();
          else if (rawDays is String) tDays = int.tryParse(rawDays) ?? 3;

          // Status counts
          if (tStatus == 'COMPLETED') completedCount++; else openCount++;

          // Friendly status + progress
          String friendlyStatus = 'Pending';
          Color statusColor = const Color(0xffF59E0B);
          double progress = 0.0;
          switch (tStatus) {
            case 'WIP':
              friendlyStatus = 'In Progress'; statusColor = const Color(0xff2563EB); progress = 0.5;
              break;
            case 'COMPLETED':
              friendlyStatus = 'Completed'; statusColor = const Color(0xff10B981); progress = 1.0;
              break;
            case 'SUBMIT_REVIEW':
            case 'UNDER_REVIEW':
              friendlyStatus = 'Under Review'; statusColor = const Color(0xff7C3AED); progress = 0.8;
              break;
            case 'REWORK':
              friendlyStatus = 'Rework'; statusColor = const Color(0xffEF4444); progress = 0.3;
              break;
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
              if (diff > 0) ganttDuration = diff;
            } catch (_) {}
          }

          final taskItem = TaskItem.fromJson(t, _project!, m);
          taskModels.add(TaskModel(
            code: tCd,
            name: tName,
            assignedTo: 'Assigned',
            priority: tDays <= 2 ? 'High' : tDays <= 5 ? 'Medium' : 'Low',
            dueDate: _formatDbDate(tEndRaw),
            status: friendlyStatus,
            progress: progress,
            priorityColor: tDays <= 2
                ? const Color(0xffEF4444)
                : tDays <= 5
                    ? const Color(0xffF59E0B)
                    : const Color(0xff2563EB),
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
          status: sts == 'COMPLETED'
              ? 'Completed'
              : sts == 'HOLD'
                  ? 'On Hold'
                  : 'In Progress',
          color: sts == 'COMPLETED'
              ? const Color(0xff10B981)
              : sts == 'HOLD'
                  ? const Color(0xffF59E0B)
                  : const Color(0xff2563EB),
        ));
      }

      if (mounted) {
        setState(() {
          _milestones = milestoneModels;
          _tasks     = taskModels;
          _ganttData = ganttModels;
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

  List<GanttItemModel> get _currentTasks {
    if (_selectedMilestone == "All Milestones") {
      return _ganttData;
    } else {
      return _ganttData.where((item) => item.milestoneName == _selectedMilestone).toList();
    }
  }

  Color get _currentColor {
    if (_selectedMilestone == "All Milestones" || _milestones.isEmpty) {
      return const Color(0xff2563EB);
    }
    final matchingMilestone = _milestones.firstWhere(
      (m) => m.title == _selectedMilestone,
      orElse: () => _milestones.first,
    );
    return matchingMilestone.color;
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        onNotificationTap: () {},
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xff1E293B)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
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
                              ? _buildMyTasksTabContent()
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

  Widget _buildGanttChartTabContent() {
    double currentDayWidth = _baseDayWidth * _scaleFactor;
    if (currentDayWidth < 14) currentDayWidth = 14;
    if (currentDayWidth > 80) currentDayWidth = 80;

    final List<GanttItemModel> tasks = _currentTasks;
    final Color milestoneColor = _currentColor;

    // Calculate max day from tasks
    final int maxDay = tasks.isEmpty
        ? 30
        : tasks
            .map((e) => e.startDay + e.durationDays - 1)
            .reduce((a, b) => a > b ? a : b);

    // Generate visible days based on max day
    final List<int> visibleDays = List.generate(maxDay, (index) => index + 1);
    
    final double totalGanttTimelineWidth = visibleDays.length * currentDayWidth;

    // Calculate exact heights
    final double stackHeight = (tasks.length * rowHeight) + 70;
    final double totalChartHeight = ganttHeaderHeight + stackHeight + 20;

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
                            mainAxisSize: MainAxisSize.min,
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
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedMilestone = value!;
                          _selectedTaskId = null;
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
            height: totalChartHeight,
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
                  height: totalChartHeight,
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
                                return SizedBox(
                                  width: currentDayWidth,
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: GoogleFonts.inter(
                                        fontSize: currentDayWidth < 18 ? 7 : 9,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff64748B),
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
                              children: List.generate(tasks.length + 1, (index) {
                                return Container(
                                  height: rowHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: index == tasks.length ? Colors.transparent : const Color(0xffF1F5F9),
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
                              final isSelected = _selectedTaskId == task.id;

                              Color taskColor;
                              if (task.milestoneName.contains("Milestone 1") || 
                                  task.milestoneName.contains("Milestone 2")) {
                                taskColor = const Color(0xff10B981);
                              } else {
                                taskColor = const Color(0xff2563EB);
                              }

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
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedTaskId = isSelected ? null : task.id;
                                            });
                                          },
                                          child: Container(
                                            width: barWidth,
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? taskColor 
                                                  : taskColor.withValues(alpha: 0.8),
                                              borderRadius: BorderRadius.circular(4),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: taskColor.withValues(alpha: 0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ]
                                                  : [],
                                              border: isSelected
                                                  ? Border.all(color: Colors.white, width: 2)
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              task.milestoneName,
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
                                      
                                      // Task Name
                                      if (isSelected)
                                        Positioned(
                                          top: barHeight + 2,
                                          left: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: const Color(0xffE2E8F0)),
                                            ),
                                            child: Text(
                                              task.taskName,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Color(0xff475569),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
            child: Row(
              children: [
                _buildGanttLegend('Project Initiation', const Color(0xff10B981)),
                const SizedBox(width: 16),
                _buildGanttLegend('Civil Construction', const Color(0xff2563EB)),
                const SizedBox(width: 16),
                _buildGanttLegend('Selected', const Color(0xff0F172A)),
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
          Tab(text: 'Milestones'),
          Tab(text: 'Gantt Chart'),
          Tab(text: 'My Tasks'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }

  Widget _buildOverviewTabContent() {
    return Column(
      children: [
        _buildTaskSummaryCard(),
        const SizedBox(height: 12),
        _buildProjectProgressCard(),
        const SizedBox(height: 12),
        _buildProjectInformationCard(),
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
                  bool isCompleted = milestone.status == "Completed";
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
                                    Text('Target: ${milestone.targetDate}', style: const TextStyle(fontSize: 9.5, color: Color(0xff475569))),
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
    final filteredTasks = _tasks.where((t) => t.milestoneTitle == _selectedMilestoneTitle).toList();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.assignment_outlined, size: 18, color: Color(0xff2563EB)),
                  SizedBox(width: 8),
                  Text('TASKS ASSIGNED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
                ],
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: const [
                    Text('View all', style: TextStyle(fontSize: 11, color: Color(0xff2563EB), fontWeight: FontWeight.w600)),
                    Icon(Icons.arrow_forward, size: 12, color: Color(0xff2563EB)),
                  ],
                ),
              )
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(task.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff2563EB))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(task.priority, style: TextStyle(color: task.priorityColor, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
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
                                Text('To: ${task.assignedTo}', style: const TextStyle(fontSize: 10.5, color: Color(0xff475569))),
                                (() {
                                  final String roleText = task.code == 'PRJ-001-T03' ? 'Reviewer' : task.code == 'PRJ-001-T04' ? 'Approver' : 'Assignee';
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

  Widget _buildMyTasksTabContent() {
    if (_tasks.isEmpty) {
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
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No tasks assigned to you in this project',
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
              Icon(Icons.check_box_outlined, size: 18, color: Color(0xff2563EB)),
              SizedBox(width: 8),
              Text('MY TASKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xffF1F5F9), thickness: 1),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xffF8FAFC), height: 16),
            itemBuilder: (context, index) {
              final task = _tasks[index];
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(task.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff2563EB))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(task.priority, style: TextStyle(color: task.priorityColor, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(task.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff0F172A))),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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

  Widget _buildProjectBannerCard() {
    final String prjName = _project?.prjNm ?? 'No Project Name';
    final String prjDesc = _project?.prjDesc ?? 'No Description';
    final String prjStatus = _project?.prjSts ?? 'LIVE';
    final String prjPriority = _project?.prjPrty ?? 'Medium';
    final Color priorityColor = getPriorityColor(prjPriority);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/company.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: const Color(0xffF1F5F9),
                      child: const Icon(
                        Icons.business,
                        color: Color(0xff94A3B8),
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prjName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _projectLocation,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                prjStatus,
                style: const TextStyle(
                  color: Color(0xff475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xffEDF2F7), thickness: 1, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopMetaItem(
                'Start Date',
                _project?.stDt ?? 'N/A',
                Icons.calendar_today_outlined,
                iconColor: Colors.green,
              ),
              _buildTopMetaItem(
                'Target Date',
                _project?.endDt ?? 'N/A',
                Icons.event_outlined,
                iconColor: Colors.orange,
              ),
              _buildTopMetaItem(
                'Priority',
                prjPriority,
                Icons.flag_outlined,
                iconColor: priorityColor,
                textColor: priorityColor,
              ),
            ],
          ),
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

  Widget _buildTaskSummaryCard() {
    final totalCount = _tasks.length;
    final inProgressCount = _tasks.where((t) => t.status == 'In Progress').length;
    final openCount = _tasks.where((t) => t.status == 'Pending' || t.status == 'Open').length;
    final completedCount = _tasks.where((t) => t.status == 'Completed').length;

    return _buildSectionCard(
      title: 'TASK SUMMARY',
      icon: Icons.assignment_outlined,
      iconColor: Colors.blue,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        children: [
          _buildTaskBlock('Tasks Assigned', '$totalCount', Icons.assignment_turned_in_outlined, Colors.green),
          _buildTaskBlock('In Progress', '$inProgressCount', Icons.play_circle_outline, Colors.blue),
          _buildTaskBlock('Open Tasks', '$openCount', Icons.query_builder, Colors.orange),
          _buildTaskBlock('Completed', '$completedCount', Icons.check_circle_outline, Colors.red),
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
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.status == 'Completed').length;
    final inProgress = _tasks.where((t) => t.status == 'In Progress').length;
    final yetToStart = total - completed - inProgress;

    final double completedPct = total == 0 ? 0.0 : (completed / total);
    final double inProgressPct = total == 0 ? 0.0 : (inProgress / total);
    final double yetToStartPct = total == 0 ? 0.0 : (yetToStart / total);

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
                    const Text('Completed', style: TextStyle(fontSize: 8, color: Color(0xff64748B))),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildProgressLegend('Completed', '${(completedPct * 100).round()}%', Colors.green),
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

  Widget _buildProjectInformationCard() {
    return _buildSectionCard(
      title: 'PROJECT INFORMATION',
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildRowDetail('Project Code', _project?.prjCd ?? 'N/A'),
          _buildRowDetail('Project Type', 'CBG Plant'),
          _buildRowDetail('Location', 'Site Location'),
          _buildRowDetail('Client', 'Atirath Bio Energy Pvt. Ltd.'),
          const SizedBox(height: 10),
          const Align(alignment: Alignment.centerLeft, child: Text('Description', style: TextStyle(fontSize: 11, color: Color(0xff64748B)))),
          const SizedBox(height: 4),
          Text(_project?.prjDesc ?? 'No description provided.', style: const TextStyle(fontSize: 11.5, color: Color(0xff1E293B), height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildUpcomingMilestonesCard() {
    final upcoming = _milestones.take(4).toList();
    return _buildSectionCard(
      title: 'UPCOMING MILESTONES',
      icon: Icons.flag_outlined,
      iconColor: Colors.blue,
      child: Column(
        children: upcoming.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('No upcoming milestones', style: TextStyle(fontSize: 11, color: Colors.grey)),
                )
              ]
            : List.generate(upcoming.length, (index) {
                final m = upcoming[index];
                return _buildMilestoneRow(m.title, m.targetDate, isLast: index == upcoming.length - 1);
              }),
      ),
    );
  }

  Widget _buildMilestoneRow(String title, String date, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xffF1F5F9), width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11.5, color: Color(0xff1E293B), fontWeight: FontWeight.w500))),
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
}